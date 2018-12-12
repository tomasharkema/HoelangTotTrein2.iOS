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
import HoelangTotTreinCore

#if canImport(HoelangTotTreinAPIWatch)
import HoelangTotTreinAPIWatch
#endif
#if canImport(HoelangTotTreinAPI)
import HoelangTotTreinAPI
#endif
import Promissum

/// a service to notify users that they need to transfer.
class TransferService: NSObject {

  private let radius: CLLocationDistance
  private let travelService: TravelService
  private let dataStore: DataStore
  private let preferenceStore: PreferenceStore
  private let locationManager = CLLocationManager()
  
//  private let geofenceValue: Variable<GeofenceModel?> = Variable(nil)
//  fileprivate(set) var geofenceObservable: Observable<GeofenceModel>!

  private let geofenceSource = VariableSource<GeofenceModel?>(value: nil)
  public let geofence: Variable<GeofenceModel?>

  var advices: Advices? = [] {
    didSet {
      guard let advices = advices else { return }
      updateGeofences(for: advices)
    }
  }

  init(travelService: TravelService, dataStore: DataStore, preferenceStore: PreferenceStore, radius: CLLocationDistance = 200) {
    self.radius = radius
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
    let region = CLCircularRegion(center: station.coords.location.coordinate, radius: radius, identifier: station.name)
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
    
    let newAdviceIsFirstLeg = newAdvice.reisDeel.first?.ritNummer.map { preferenceStore.firstLegRitNummers.contains($0) } ?? false
    
    let geofenceType: GeofenceType
    if newAdvice.startStation == request.from?.name {
      geofenceType = .start
    } else if newAdviceIsFirstLeg {
      geofenceType = .tussenStation
    } else if request.to == station {
      geofenceType = .end
    } else if newAdvice.startStation == station.name {
      geofenceType = .overstap
    } else {
      geofenceType = .tussenStation
    }
    
    guard let stop = newAdvice.reisDeel.first?.stops.first else {
      return nil
    }
    
    return GeofenceModel(type: geofenceType, stationName: newAdvice.startStation!, stop: stop)
  }
  
  private func notify(for newAdvice: Advice, request: AdviceRequest, station: Station) {
    guard let geofenceModel = self.geofenceModel(for: newAdvice, request: request, station: station) else {
      return
    }
    
    notify(geofenceModel: geofenceModel)
  }
  
  private func notify(geofenceModel: GeofenceModel) {
    geofenceSource.value = geofenceModel
    if geofenceModel.type != .tussenStation {
      _ = travelService.setStation(.from, stationName: geofenceModel.stationName)
    }
  }

  private func arrive(at station: Station) {

    let request = travelService.pickedAdviceRequest.value
    let newRequest: AdviceRequest
    if station == request.to {
      newRequest = AdviceRequest(from: request.to, to: request.from)
    } else {
      newRequest = AdviceRequest(from: station, to: request.to)
    }

    travelService.fetchAdvices(for: newRequest)
      .map { ($0.trips.filter { $0.isOngoing }, request) }
      .then { (advices, request) in
        if let newAdvice = advices.first {
          self.notify(for: newAdvice, request: request, station: station)
        }
      }
  }

  private func arrive(at stationName: String) {
    dataStore.find(stationName: stationName)
      .then { currentStation in
        self.arrive(at: currentStation)
      }
  }

}

extension TransferService: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    arrive(at: region.identifier)
  }
}
