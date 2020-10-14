//
//  TransferService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 30-09-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreLocation
import Bindable
import API
import Core
import Promissum

/// a service to notify users that they need to transfer.
class TransferService: NSObject {

  private let travelService: TravelService
  private let dataStore: DataStore
  private let preferenceStore: PreferenceStore
  private let locationManager = CLLocationManager()

  private let geofenceSource = VariableSource<GeofenceModel?>(value: nil)
  public let geofence: Variable<GeofenceModel?>

  var advices: AdvicesAndRequest? = nil {
    didSet {
      guard let advices = advices else { return }
      updateGeofences(for: advices.advices)
    }
  }

  init(travelService: TravelService, dataStore: DataStore, preferenceStore: PreferenceStore) {
    self.travelService = travelService
    self.dataStore = dataStore
    self.preferenceStore = preferenceStore

    geofence = geofenceSource.variable

    super.init()
    locationManager.delegate = self
    start()
  }

  func start() {
    bind(\.advices, to: travelService.currentAdvices.map { $0.value })
  }

  private func getStationNames(from advice: Advice) -> Set<String> {
    return Set(advice.legs.flatMap {
      $0.stops.map {
        $0.name
      }
    })
  }

  private func resetGeofences() {
    locationManager.monitoredRegions.forEach {
      locationManager.stopMonitoring(for: $0)
    }
  }

  private func updateGeofence(for station: Station) {
    let region = CLCircularRegion(center: station.coords.location.coordinate, radius: station.naderenRadius, identifier: station.UICCode.rawValue)
    locationManager.startMonitoring(for: region)
  }

  private func updateGeofences(for advices: Advices) {
    let stationNames = Set(advices.flatMap { getStationNames(from: $0) })

    let stationPromises = whenAll(stationNames.map { dataStore.find(stationName: $0) })

    stationPromises.then { stations in
      self.resetGeofences()
      stations.forEach { self.updateGeofence(for: $0) }
    }
    let ritNummers = advices.compactMap { $0.legs.first }.compactMap { $0.journeyDetailRef }
    preferenceStore.firstLegRitNummers = ritNummers
  }
  
  private func geofenceModel(for newAdvice: Advice, request: AdviceRequest, station: Station) -> GeofenceModel? {
    
    let newAdviceIsFirstLeg = (newAdvice.legs.first?.journeyDetailRef).map { preferenceStore.firstLegRitNummers.contains($0) } ?? false
    
    let geofenceType: GeofenceType
    if newAdvice.startStation?.uicCode == request.from {
      geofenceType = .start
    } else if newAdviceIsFirstLeg {
      geofenceType = .tussenStation
    } else if request.to == station.UICCode {
      geofenceType = .end
    } else if newAdvice.startStation?.uicCode == station.UICCode {
      geofenceType = .overstap
    } else {
      geofenceType = .tussenStation
    }
    
    guard let stop = newAdvice.legs.first?.stops.first else {
      return nil
    }
    
    return GeofenceModel(type: geofenceType, uicCode: newAdvice.startStation!.uicCode, stop: stop)
  }
  
  private func notify(for newAdvice: Advice, request: AdviceRequest, station: Station) {
    guard let geofenceModel = self.geofenceModel(for: newAdvice, request: request, station: station) else {
      return
    }
    
    notify(geofenceModel: geofenceModel)
  }
  
  private func notify(geofenceModel: GeofenceModel) {
    geofenceSource.value = geofenceModel
    
    switch geofenceModel.type {
    case .start:
      break
    case .tussenStation:
      break
    case .overstap:
      _ = travelService.setStation(.from, byPicker: false, uicCode: geofenceModel.uicCode)
    case .end:
      _ = travelService.setStation(.from, byPicker: true, uicCode: geofenceModel.uicCode)
    }
    
  }

  private func arrive(at station: Station) {

    let request = travelService.adviceRequest.value
    let newRequest: AdviceRequest
    if station.UICCode == request.to {
      newRequest = AdviceRequest(from: request.to, to: request.from)
    } else {
      newRequest = AdviceRequest(from: station.UICCode, to: request.to)
    }

    travelService.fetchAdvices(for: newRequest, cancellationToken: nil)
      .map { ($0.trips.filter { $0.isOngoing }, request) }
      .then { (advices, request) in
        if let newAdvice = advices.first {
          self.notify(for: newAdvice, request: request, station: station)
        }
      }
  }

  private func arrive(at uicCode: UicCode) {
    dataStore.find(uicCode: uicCode)
      .then { currentStation in
        self.arrive(at: currentStation)
      }
  }

}

extension TransferService: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    arrive(at: UicCode(rawValue: region.identifier))
  }
}
