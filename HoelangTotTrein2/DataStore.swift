//
//  DataStore.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 01-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import Promissum

enum DataStoreError: Error {
  case notFound
}

class DataStore {

  fileprivate let persistentContainer: NSPersistentContainer

  init (useInMemoryStore: Bool = false) {

    persistentContainer = NSPersistentContainer(name: "DataModel")

    if useInMemoryStore {
      let description = NSPersistentStoreDescription()
      description.type = NSInMemoryStoreType
      persistentContainer.persistentStoreDescriptions = [description]
    }

    persistentContainer.loadPersistentStores { _, error in
      if let error = error {
        fatalError(error.localizedDescription)
      }
    }
  }
}

// Stations

extension Station {
  init?(record: StationRecord) {
    guard let name = record.name,
      let code = record.code,
      let land = record.land,
      let lat = record.lat?.doubleValue,
      let long = record.lon?.doubleValue
      else {
        return nil
    }

    self.name = name
    self.code = code
    self.land = land
    self.coords = Coords(lat: lat, lon: long)
    self.type = record.type.flatMap { StationType(rawValue: $0) }
  }
}

extension DataStore {
  func findOrUpdate(stations: [Station]) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()

    persistentContainer.performBackgroundTask { context in
      do {
        for station in stations {
          let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
          fetchRequest.predicate = NSPredicate(format: "code = %@", #keyPath(StationRecord.code), station.code)

          if let stationRecord = try context.fetch(fetchRequest).first {
            stationRecord.name = station.name
            stationRecord.land = station.land
            stationRecord.type = station.type?.rawValue
          } else {
            let newStation = StationRecord(context: context)
            newStation.name = station.name
            newStation.code = station.code
            newStation.land = station.land
            newStation.lat = station.coords.lat as NSNumber
            newStation.lon = station.coords.lon as NSNumber
            newStation.type = station.type?.rawValue
          }
        }

        try context.save()
        promiseSource.resolve()
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

  fileprivate func findRecord(stationCode: String) -> Promise<StationRecord, Error> {
    let promiseSource = PromiseSource<StationRecord, Error>()

    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "code = %@", #keyPath(StationRecord.code), stationCode)

      do {
        guard let record = try context.fetch(fetchRequest).first else {
          throw DataStoreError.notFound
        }
        promiseSource.resolve(record)
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

  func find(stationCode: String) -> Promise<Station, Error> {
    return findRecord(stationCode: stationCode).flatMap {
      guard let station = Station(record: $0) else {
        return Promise(error: DataStoreError.notFound)
      }

      return Promise(value: station)
    }
  }

  fileprivate func findRecord(stationName: String) -> Promise<StationRecord, Error> {
    let promiseSource = PromiseSource<StationRecord, Error>()

    persistentContainer.performBackgroundTask { context in

      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "name = %@", #keyPath(StationRecord.name), stationName)

      do {
        guard let station = try context.fetch(fetchRequest).first else {
          throw DataStoreError.notFound
        }

        promiseSource.resolve(station)
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

  func find(stationName: String) -> Promise<Station, Error> {
    return findRecord(stationName: stationName).flatMap {
      guard let station = Station(record: $0) else {
        return Promise(error: DataStoreError.notFound)
      }

      return Promise(value: station)
    }
  }

  func find(inBounds bounds: Bounds) -> Promise<[Station], Error> {
    let promiseSource = PromiseSource<[Station], Error>()

    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "lat > %f AND lat < %f AND lon > %f AND lon < %f", bounds.latmin, bounds.latmax, bounds.lonmin, bounds.lonmax)

      do {
        promiseSource.resolve(try context.fetch(fetchRequest).flatMap { Station(record: $0) })
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }
}

// History

extension DataStore {

  func insertHistory(station: Station, historyType: HistoryType) -> Promise<Void, Error> {
    return findRecord(stationCode: station.code).flatMap { record in
      self.insertHistory(stationRecord: record, historyType: historyType)
    }
  }

  func insertHistory(stationRecord: StationRecord, historyType: HistoryType) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()
    persistentContainer.performBackgroundTask { context in
      let history = History(context: context)
      history.station = stationRecord
      history.date = NSDate()
      history.historyType = historyType
    }
    return promiseSource.promise
  }
}
