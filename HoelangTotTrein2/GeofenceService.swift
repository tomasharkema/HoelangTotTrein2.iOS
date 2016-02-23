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

class GeofenceService: NSObject {

  private let queue = dispatch_queue_create("nl.tomasharkema.GeofenceService", DISPATCH_QUEUE_SERIAL)

  private let locationManager = CLLocationManager()

  private let travelService: TravelService

  private var currentAdvicesObservableSubject: ObservableSubject<Advices>!

  private var stationGeofences = [String: [GeofenceModel]]()

  let geofenceObservable = Observable<GeofenceModel>()

  init(travelService: TravelService) {
    self.travelService = travelService
  }

  private func updateGeofence(stationCode: String, geofenceModels: [GeofenceModel]) {
    let predicate = NSPredicate(format: "code = %@", stationCode)
    do {
      if let station = try CDK.mainThreadContext.findFirst(StationRecord.self, predicate: predicate, sortDescriptors: nil, offset: nil)?.toStation() {

        let region = CLCircularRegion(center: station.coords.location.coordinate, radius: 300, identifier: station.code)
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

  func attach() {
    locationManager.delegate = self
    currentAdvicesObservableSubject = travelService.currentAdvicesObservable.subscribe(queue) { [weak self] advices in

      guard let service = self else {
        return
      }

      service.stationGeofences = [String: [GeofenceModel]]()

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
                toCreateGeofences[stop.name] = GeofenceModel(type: geofenceType, station: fromDict.station, fromStop: fromDict.fromStop, toStop: stop)
              }
            } else {
              let predicate = NSPredicate(format: "name = %@", stop.name)
              do {
                if let station = try CDK.mainThreadContext.findFirst(StationRecord.self, predicate: predicate, sortDescriptors: nil, offset: nil)?.toStation() {
                  toCreateGeofences[stop.name] = GeofenceModel(type: geofenceType, station: station, fromStop: stop, toStop: nil)
                }
              } catch {
                print(error)
              }
            }
          }
        }

        for (_, v) in toCreateGeofences {
          if let arr = service.stationGeofences[v.station.code] {
            service.stationGeofences[v.station.code] = arr + [v]
          } else {
            service.stationGeofences[v.station.code] = [v]
          }
        }
      }
      self?.resetGeofences()
      UserDefaults.geofenceInfo = service.stationGeofences
      for (stationCode, geo) in service.stationGeofences {
        self?.updateGeofence(stationCode, geofenceModels: geo)
      }
    }
  }

  deinit {
    travelService.currentAdvicesObservable.unsubscribe(currentAdvicesObservableSubject)
  }

}

extension GeofenceService: CLLocationManagerDelegate {
  
  func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
    print("didStartMonitoringForRegion", region)
  }
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    dispatch_async(queue) { [weak self] in

      self?.travelService.currentAdviceObservable.once { advices in
        print("NEW ADVICES AFTER GEOFENCE")
      }

      guard let service = self, geofences = service.stationGeofences[region.identifier] else {
        return
      }
      
      let now = NSDate().timeIntervalSince1970
      print("DID ENTER REGION, \(region)")
      let stortedGeofences = geofences.enumerate().lazy.sort { (l,r) in
        l.element.fromStop?.time < r.element.fromStop?.time
      }
      
      let toFireGeofence = stortedGeofences.filter {
        let offset: Double = 13 * 60
        //let smaller = ($0.element.fromStop?.time ?? 0) + offset < now
        let greater = ($0.element.fromStop?.time ?? 0) - offset > now
        
        return greater//smaller && greater
      }

      if let (_, geofence) = toFireGeofence.first {
        self?.geofenceObservable.next(geofence)
      }
    }
  }
}
