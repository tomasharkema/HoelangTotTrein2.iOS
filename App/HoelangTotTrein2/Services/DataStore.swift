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
import HoelangTotTreinAPI

enum DataStoreError: Error {
  case notFound
}

class DataStore {
  fileprivate let queue = DispatchQueue(label: "Datastore")
  fileprivate let persistentContainer: NSPersistentContainer

  init (useInMemoryStore: Bool = false) {

    persistentContainer = NSPersistentContainer(name: "HoelangTotTrein2")

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

  func stations() -> Promise<[Station], Error> {
    let promiseSource = PromiseSource<[Station], Error>()

    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
      do {
        promiseSource.resolve(try context.fetch(fetchRequest).flatMap({ Station(record: $0)}))
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

  func findOrUpdate(stations: [Station]) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()

    persistentContainer.performBackgroundTask { context in
      do {
        for station in stations {
          let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
          fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(StationRecord.code), station.code)

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

  func find(stationName: String) -> Promise<Station, Error> {
    let promiseSource = PromiseSource<Station, Error>()

    persistentContainer.performBackgroundTask { context in

      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(StationRecord.name), stationName)

      do {
        guard let station = try context.fetch(fetchRequest).first.flatMap({Station(record: $0)}) else {
          throw DataStoreError.notFound
        }

        promiseSource.resolve(station)
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

  func find(stationCode: String) -> Promise<Station, Error> {
    let promiseSource = PromiseSource<Station, Error>()

    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(StationRecord.code), stationCode)

      do {
        guard let record = try context.fetch(fetchRequest)
          .first
          .flatMap({ Station(record: $0) })
        else {
          throw DataStoreError.notFound
        }
        promiseSource.resolve(record)
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
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

  func find(stationNameContains query: String) -> Promise<[Station], Error> {
    let promiseSource = PromiseSource<[Station], Error>()
    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(StationRecord.name), query)
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
      
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
    let promiseSource = PromiseSource<Void, Error>()
    persistentContainer.performBackgroundTask { context in

      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(StationRecord.code), station.code)

      do {
        guard let stationRecord = try context.fetch(fetchRequest).first else {
          throw DataStoreError.notFound
        }

        let history = History(context: context)
        history.stationCode = station.code
        history.station = stationRecord
        history.date = NSDate()
        history.historyType = historyType

        try context.save()
        promiseSource.resolve()
      } catch {
        promiseSource.reject(error)
      }
    }
    return promiseSource.promise
  }

  private func fetchMostUsedDict() -> Promise<[(String, Int)], Error> {
    let promiseSource = PromiseSource<[(String, Int)], Error>()

    persistentContainer.performBackgroundTask { context in
      let stationCodeKeyPath = #keyPath(History.stationCode)
      guard let entity = NSEntityDescription.entity(forEntityName: "History", in: context),
        let stationCode = entity.attributesByName[stationCodeKeyPath] else {
        promiseSource.reject(DataStoreError.notFound)
        return
      }

      let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest<NSDictionary>(entityName: "History")
      fetchRequest.resultType = .dictionaryResultType
      fetchRequest.propertiesToGroupBy = [#keyPath(History.stationCode)]

      let countExpression = NSExpressionDescription()
      countExpression.name = "count"
      countExpression.expressionResultType = .integer64AttributeType
      let stationCodeExpression = NSExpression(forKeyPath: #keyPath(History.stationCode))
      countExpression.expression = NSExpression(forFunction: "count:", arguments: [stationCodeExpression])

      fetchRequest.propertiesToFetch = [stationCode, countExpression]

      do {
        let result = try context.fetch(fetchRequest)
        guard let results = result as? [[String: Any]] else {
          throw DataStoreError.notFound
        }

        let arr = results
          .flatMap { dict -> (String, Int)? in
            guard let code = dict["stationCode"] as? String,
              let count = dict["count"] as? Int
              else { return nil }

            return (code, count)
          }
          .sorted { (lhs, rhs) in
            lhs.1 > rhs.1
          }

        promiseSource.resolve(arr)
      } catch {
        promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

  func mostUsedStations() -> Promise<[Station], Error>  {
    return fetchMostUsedDict()
      .dispatch(on: queue)
      .flatMap { stationCodes in
        whenAll(stationCodes.map({ (code, _) in
          self.find(stationCode: code)
        }))
      }
      .dispatchMain()
  }

}
