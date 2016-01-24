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

        let region = CLCircularRegion(center: station.coords.location.coordinate, radius: 150, identifier: station.code)
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
//                print("overstappen op \(fromDict.station.name)")
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
          if var p = service.stationGeofences[v.station.code] {
            service.stationGeofences[v.station.code] = service.stationGeofences[v.station.code]! + [v]
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

  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    dispatch_async(queue) { [weak self] in
      guard let service = self, geofences = service.stationGeofences[region.identifier] else {
        return
      }
      print("DID ENTER REGION, \(region)")

      let toFireGeofence = geofences.lazy.filter {
        $0.fromStop?.time > NSDate().timeIntervalSince1970
      }
      if let geofence = toFireGeofence.first {
        self?.geofenceObservable.next(geofence)
      }
    }
  }


}
