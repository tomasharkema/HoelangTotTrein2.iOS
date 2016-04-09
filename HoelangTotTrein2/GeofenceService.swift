//
//  GeofenceService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreDataKit
import CoreLocation
import RxSwift

typealias StationName = String

class GeofenceService: NSObject {

  typealias GeofenceModels = [GeofenceModel]
  typealias StationGeofences = [StationName: GeofenceModels]

  private static let queue = dispatch_queue_create("nl.tomasharkema.GeofenceService", DISPATCH_QUEUE_SERIAL)
  private let scheduler = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: "nl.tomasharkema.GeofenceService")
  private let locationManager = CLLocationManager()

  private let travelService: TravelService

  private var currentAdvicesObservableSubject: Disposable?
  private var geofenceObservableAfterAdvicesUpdateSubject: Disposable?

  private var stationGeofences = StationGeofences()

  let geofenceObservable = Variable<GeofenceModel?>(nil)
  let geofenceObservableAfterAdvicesUpdate = Variable<GeofenceModel?>(nil)

  init(travelService: TravelService) {
    self.travelService = travelService
  }

  private func updateGeofenceWithStationName(stationName: StationName, geofenceModels: [GeofenceModel]) {
    let predicate = NSPredicate(format: "name = %@", stationName)
    do {
      if let station = try CDK.mainThreadContext.findFirst(StationRecord.self, predicate: predicate, sortDescriptors: nil, offset: nil)?.toStation() {

        let region = CLCircularRegion(center: station.coords.location.coordinate, radius: 150, identifier: station.name)
        locationManager.startMonitoringForRegion(region)

      }
    } catch {
      print(error)
    }
  }

  private func resetGeofences() {
    for region in locationManager.monitoredRegions {
      locationManager.stopMonitoringForRegion(region)
    }
  }

  func geofencesFromAdvices(advices: Advices) -> StationGeofences {
    var stationGeofences = StationGeofences()

    for (_, advice) in advices.enumerate() {
      var toCreateGeofences = [String: GeofenceModel]()
      for (deelIndex, deel) in advice.reisDeel.enumerate() {
        for (stopIndex, stop) in deel.stops.enumerate() {
          let geofenceType: GeofenceType
          if deelIndex == 0 && stopIndex == 0 {
            geofenceType = .Start
          } else if deelIndex != 0 && stopIndex == 0 {
            geofenceType = .Overstap
          } else if deelIndex == advice.reisDeel.count-1 && stopIndex == deel.stops.count-1 {
            geofenceType = .End
          } else {
            geofenceType = .TussenStation
          }

          if let fromDict = toCreateGeofences[stop.name] {
            if fromDict.type == .TussenStation && geofenceType == .Overstap {
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

  func attach() {
    locationManager.delegate = self
    currentAdvicesObservableSubject = travelService.currentAdvicesObservable.asObservable().observeOn(scheduler).subscribeNext { [weak self] advices in

      guard let service = self, advices = advices else {
        return
      }

      let stationGeofences = service.geofencesFromAdvices(advices)

      self?.resetGeofences()
      UserDefaults.geofenceInfo = stationGeofences
      for (stationName, geo) in stationGeofences {
        self?.updateGeofenceWithStationName(stationName, geofenceModels: geo)
      }

      service.stationGeofences = stationGeofences
    }

    geofenceObservableAfterAdvicesUpdateSubject = geofenceObservable.asObservable().observeOn(scheduler)
      .flatMap { value in
        App.travelService.currentAdviceObservable.asObservable().map { _ in value }
      }
      .subscribeNext { [weak self] value in
        if self?.geofenceObservableAfterAdvicesUpdate.value != value {
          self?.geofenceObservableAfterAdvicesUpdate.value = value
        }
      }

  }

  deinit {
    currentAdvicesObservableSubject?.dispose()
    geofenceObservableAfterAdvicesUpdateSubject?.dispose()
  }

}

extension GeofenceService: CLLocationManagerDelegate {
  
  func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
    print("didStartMonitoringForRegion", region.identifier)
  }
  
  func geofenceFromGeofences(stationGeofences: GeofenceModels, forTime time: NSDate) -> GeofenceModel? {
    let now = time.timeIntervalSince1970
    
    let stortedGeofences = stationGeofences.enumerate().lazy.sort { (l,r) in
      l.element.fromStop?.time < r.element.fromStop?.time
    }
    
    let toFireGeofence = stortedGeofences.filter { geofence in
      let offset: Double = 13 * 60
      
      switch (geofence.element.fromStop, geofence.element.toStop) {
      
      case (let fromStop?, let toStop?):
        return fromStop.time - offset >= now && toStop.time - 60 > now
        
      case (let fromStop?, _):
        if geofence.element.type == .TussenStation {
          return fromStop.time + offset >= now
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
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    dispatch_sync(GeofenceService.queue) { [weak self] in
      guard let service = self, geofences = service.stationGeofences[region.identifier] else {
        return
      }
      
      print("DID ENTER REGION, \(region)")
      
      if let geofence = service.geofenceFromGeofences(geofences, forTime: NSDate()) {
        if self?.geofenceObservable.value != geofence {
          self?.geofenceObservable.value = geofence
        }
      }
    }
  }
}
