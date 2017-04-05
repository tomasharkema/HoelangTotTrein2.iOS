//
//  GeofenceService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


typealias StationName = String

class GeofenceService: NSObject {

  typealias GeofenceModels = [GeofenceModel]
  typealias StationGeofences = [StationName: GeofenceModels]

  fileprivate static let queue = DispatchQueue(label: "nl.tomasharkema.GeofenceService", attributes: [])
  fileprivate let scheduler = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: "nl.tomasharkema.GeofenceService")
  fileprivate let locationManager = CLLocationManager()

  fileprivate let travelService: TravelService
  private let dataStore: DataStore

  fileprivate let disposeBag = DisposeBag()

  fileprivate var stationGeofences = StationGeofences()

  fileprivate(set) var geofenceObservable: Observable<GeofenceModel>!
//  private(set) var geofenceObservableAfterAdvicesUpdate: Observable<(oldModel: GeofenceModel, updatedModel: GeofenceModel)>!

  init(travelService: TravelService, dataStore: DataStore) {
    self.travelService = travelService
    self.dataStore = dataStore
    super.init()
    attach()
  }

  fileprivate func updateGeofenceWithStationName(_ stationName: StationName, geofenceModels: [GeofenceModel]) {
    dataStore.find(stationName: stationName)
      .dispatch(on: GeofenceService.queue)
      .then { station in
        let region = CLCircularRegion(center: station.coords.location.coordinate, radius: 150, identifier: station.name)
        self.locationManager.startMonitoring(for: region)
      }
      .trap { print($0) }
  }

  fileprivate func resetGeofences() {
    for region in locationManager.monitoredRegions {
      locationManager.stopMonitoring(for: region)
    }
  }

  func geofencesFromAdvices(_ advices: Advices) -> StationGeofences {
    var stationGeofences = StationGeofences()

    for (_, advice) in advices.enumerated() {
      var toCreateGeofences = [String: GeofenceModel]()
      for (deelIndex, deel) in advice.reisDeel.enumerated() {
        for (stopIndex, stop) in deel.stops.enumerated() {
          let geofenceType: GeofenceType
          if deelIndex == 0 && stopIndex == 0 {
            geofenceType = .start
          } else if deelIndex != 0 && stopIndex == 0 {
            geofenceType = .overstap
          } else if deelIndex == advice.reisDeel.count-1 && stopIndex == deel.stops.count-1 {
            geofenceType = .end
          } else {
            geofenceType = .tussenStation
          }

          if let fromDict = toCreateGeofences[stop.name] {
            if fromDict.type == .tussenStation && geofenceType == .overstap {
              toCreateGeofences[stop.name] = GeofenceModel(type: geofenceType, stationName: fromDict.stationName, fromStop: fromDict.fromStop, toStop: stop)
            }
          } else {
            toCreateGeofences[stop.name] = GeofenceModel(type: geofenceType, stationName: stop.name, fromStop: stop, toStop: nil)
          }
        }
      }

      for (_, v) in toCreateGeofences {
        if let arr = stationGeofences[v.stationName] {
          stationGeofences[v.stationName] = arr + [v]
        } else {
          stationGeofences[v.stationName] = [v]
        }
      }
    }

    return stationGeofences
  }

  fileprivate func attach() {
    let obs = travelService.currentAdvicesObservable
      .asObservable()
      .observeOn(scheduler)
      .filterOptional()
      .map { advices -> StationGeofences? in
        self.geofencesFromAdvices(advices)
      }
      .filterOptional()

    obs.subscribe(onNext: { stationGeofences in
      self.stationGeofences = stationGeofences
    }).addDisposableTo(disposeBag)

    obs
      .observeOn(scheduler)
      .subscribe(onNext: { stationGeofences in
        self.resetGeofences()
        UserDefaults.geofenceInfo = stationGeofences
        for (stationName, geo) in stationGeofences {
          self.updateGeofenceWithStationName(stationName, geofenceModels: geo)
        }
      }).addDisposableTo(disposeBag)

    geofenceObservable = locationManager.rx.didEnterRegion
      .observeOn(scheduler)
      .distinctUntilChanged()
      .map { region -> GeofenceModel? in
        guard let geofences = self.stationGeofences[region.identifier] else {
          return nil
        }

        print("DID ENTER REGION, \(region)")

        if let geofence = self.geofenceFromGeofences(geofences, forTime: Date()) {
          return geofence
        }

        return nil
      }
      .filterOptional()
  }

}

extension GeofenceService {
  
  func geofenceFromGeofences(_ stationGeofences: GeofenceModels, forTime time: Date) -> GeofenceModel? {
    let now = time.timeIntervalSince1970
    
    let stortedGeofences = stationGeofences.enumerated().lazy.sorted { (l,r) in
      l.element.fromStop?.time < r.element.fromStop?.time && l.element.toStop?.time < r.element.toStop?.time
    }
    
    let toFireGeofence = stortedGeofences.filter { geofence in
      let offset: Double = 13 * 60
      
      switch (geofence.element.fromStop, geofence.element.toStop) {
      
      case (let fromStop?, let toStop?):
        return fromStop.time - offset >= now && toStop.time - 60 > now
        
      case (let fromStop?, _):
        if geofence.element.type == .tussenStation {
          return fromStop.time + offset >= now
        }

        if geofence.element.type == .overstap {
          return fromStop.time + 5 * 60 > now
        }
        
        return fromStop.time > now
        
      default: return false
      }
    }
    
    if let (_, geofence) = toFireGeofence.first {
      return geofence
    }
    return nil
  }
}
