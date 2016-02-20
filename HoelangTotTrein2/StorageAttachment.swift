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
  var currentAdviceRequestSubscription: ObservableSubject<AdviceRequest>!
  var currentAdvicesRequestSubscription: ObservableSubject<Advices>!

  init (travelService: TravelService) {
    self.travelService = travelService
  }

  func updateStations(stations: [Station]) {
    CDK.performBlockOnBackgroundContext { context in
      do {
        for station in stations {
          let predicate = NSPredicate(format: "code = %@", station.code)
          if let stationRecord = try context.findFirst(StationRecord.self, predicate: predicate) {
            stationRecord.name = station.name
            stationRecord.land = station.land
            stationRecord.type = station.type.rawValue
          } else {
            let newStation = try context.create(StationRecord.self)
            newStation.name = station.name
            newStation.code = station.code
            newStation.land = station.land
            newStation.lat = station.coords.lat
            newStation.lon = station.coords.lon
            newStation.type = station.type.rawValue
          }
        }
        return .SaveToPersistentStore
      } catch {
        print(error)
        return .Undo
      }
    }
  }

  func attach(context: NSManagedObjectContext) {
    self.context = context

    stationObservableSubscription = travelService.stationsObservable.subscribe(queue) { [weak self] stations in
      self?.updateStations(stations)
    }

    currentAdviceRequestSubscription = travelService.currentAdviceRequest.subscribe(queue) { [weak self] request in
      self?.insertHistoryFromRequest(request)
    }

    travelService.currentAdvicesObservable.subscribe(queue) { [weak self] advices in
      if let service = self {
        service.persistCurrent(advices: advices, forAdviceRequest: service.travelService.getCurrentAdviceRequest())
      }
    }
  }

  func insertHistoryFromRequest(advice: AdviceRequest) {
    CDK.performBlockOnBackgroundContext { context in
      if let historyRecord = try? context.create(History.self), fromStation = advice.from?.getStationRecord(context) {
        historyRecord.station = fromStation
        historyRecord.date = NSDate()
        historyRecord.historyType = .From
        return .SaveToPersistentStore
      }

      return .Undo
    }
    CDK.performBlockOnBackgroundContext { context in
      if let historyRecord = try? context.create(History.self), toStation = advice.to?.getStationRecord(context) {
        historyRecord.station = toStation
        historyRecord.date = NSDate()
        historyRecord.historyType = .To
        return .SaveToPersistentStore
      }

      return .Undo
    }
  }

  private func persistCurrent(advices advices: Advices, forAdviceRequest adviceRequest: AdviceRequest) {
    UserDefaults.persistedAdvicesAndRequest = AdvicesAndRequest(advices: advices, adviceRequest: adviceRequest)
  }

  deinit {
    travelService.stationsObservable.unsubscribe(stationObservableSubscription)
    travelService.currentAdviceRequest.unsubscribe(currentAdviceRequestSubscription)
  }
}
