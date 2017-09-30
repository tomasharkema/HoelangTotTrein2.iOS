//
//  TransferService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 30-09-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import HoelangTotTreinCore
import HoelangTotTreinAPI
import Promissum

/// a service to notify users that they need to transfer.
class TransferService: NSObject {

  private let radius: CLLocationDistance
  private let travelService: TravelService
  private let dataStore: DataStore
  private let locationManager = CLLocationManager()

  private let disposeBag = DisposeBag()

  init(travelService: TravelService, dataStore: DataStore, radius: CLLocationDistance = 200) {
    self.radius = radius
    self.travelService = travelService
    self.dataStore = dataStore
    super.init()
    locationManager.delegate = self
  }

  func attach() {
    Observable.zip(travelService.currentAdvicesObservable,
                   travelService.currentAdviceObservable,
                   resultSelector: { ($0, $1) })
      .subscribe(onNext: { advicesResult, adviceResult in
        guard case .loaded(let advices) = advicesResult, let advice = adviceResult else {
          return
        }

        self.updateGeofences(for: advices, currentAdvice: advice)
      })
      .addDisposableTo(disposeBag)
  }

  private func getStationNames(from advice: Advice) -> Set<String> {
    return Set(advice.reisDeel.flatMap {
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
    self.locationManager.startMonitoring(for: region)
  }

  private func updateGeofences(for advices: Advices, currentAdvice advice: Advice) {
    let stationNames = Set(advices.flatMap { getStationNames(from: $0) })

    let stationPromises = whenAll(stationNames.map { dataStore.find(stationName: $0) })

    stationPromises.then { stations in
      self.resetGeofences()
      stations.forEach { self.updateGeofence(for: $0) }
    }
  }

  private func notify(for newAdvice: Advice, currentAdvice: Advice, station: Station, geofenceType: GeofenceType) {
    print("advice: \(newAdvice) currentAdvice: \(currentAdvice) station: \(station) geofenceType: \(geofenceType)")
    print(newAdvice.startStation)
  }

  private func arrive(at station: Station, for advice: Advice) {
    let geofenceType: GeofenceType
    if advice.startStation == station.name {
      geofenceType = .start
    } else if advice.endStation == station.name {
      geofenceType = .end
    } else {
      geofenceType = .overstap
    }

    travelService.getCurrentAdviceRequest()
      .flatMap { request -> Promise<AdvicesResult, Error> in
        let newRequest = AdviceRequest(from: station, to: request.to)
        return self.travelService.fetchAdvices(for: newRequest)
          .map { AdvicesResult(advices: $0.advices.filter { $0.isOngoing })}
      }
      .then { advicesResult in
        if let newAdvice = advicesResult.advices.first {
          self.notify(for: newAdvice, currentAdvice: advice, station: station, geofenceType: geofenceType)
        }
      }
  }

  private func arrive(at stationName: String) {
    travelService.currentAdviceObservable.filterOptional()
      .take(1)
      .subscribe(onNext: { advice in
        self.dataStore.find(stationName: stationName).then { currentStation in
          self.arrive(at: currentStation, for: advice)
        }
      })
  }

}

extension TransferService: CLLocationManagerDelegate {

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    arrive(at: region.identifier)
  }

  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
//    print("start monitoring: \(region)")
  }

}
