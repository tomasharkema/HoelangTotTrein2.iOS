//
//  StorageAttachment.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import CoreDataKit

class StorageAttachment {
  let queue = dispatch_queue_create("nl.tomasharkema.StorageAttachment", DISPATCH_QUEUE_SERIAL)
  let travelService: TravelService

  var context: NSManagedObjectContext!

  var stationObservableSubscription: ObservableSubject<[Station]>!

  init (travelService: TravelService) {
    self.travelService = travelService
  }

  func updateStations(stations: [Station]) {
    print(stations)
    for station in stations {
      CDK.performBlockOnBackgroundContext { context in
        let predicate = NSPredicate(format: "code = %@", station.code)
        do {
          if let stationRecord = try context.findFirst(StationRecord.self, predicate: predicate) {
            stationRecord.name = station.name
            stationRecord.land = station.land
            return .SaveToPersistentStore
          } else {
            let newStation = try context.create(StationRecord.self)
            newStation.name = station.name
            newStation.code = station.code
            newStation.land = station.land
            newStation.lat = station.coords.lat
            newStation.lon = station.coords.lon
            return .SaveToPersistentStore
          }

        } catch {
          print(error)
          return .Undo
        }
      }
    }
  }

  func attach(context: NSManagedObjectContext) {
    self.context = context
    stationObservableSubscription = travelService.stationsObservable.subscribe(queue) { [weak self] stations in
      self?.updateStations(stations)
    }
  }

  deinit {
    travelService.stationsObservable.unsubscribe(stationObservableSubscription)
  }
}
