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
#if os(watchOS)
import HoelangTotTreinAPIWatch
#elseif os(iOS)
import HoelangTotTreinAPI
#endif

public class AppDataStore: DataStore {
  
  fileprivate let persistentContainer: NSPersistentContainer

  public init(useInMemoryStore: Bool = false) {

    #if os(watchOS)
    let bundleIdentifier = "io.harkema.HoelangTotTreinCoreWatch"
    #else
    let bundleIdentifier = "io.harkema.HoelangTotTreinCore"
    #endif

    guard let bundle = Bundle(identifier: bundleIdentifier),
      let url = bundle.url(forResource: "HoelangTotTrein2", withExtension: "momd"),
      let model = NSManagedObjectModel(contentsOf: url)
      else {
        fatalError("NO MODEL")
        persistentContainer = NSPersistentContainer()
        return
      }

    persistentContainer = NSPersistentContainer(name: "HoelangTotTrein2", managedObjectModel: model)

    if useInMemoryStore {
      let description = NSPersistentStoreDescription()
      description.type = NSInMemoryStoreType
      persistentContainer.persistentStoreDescriptions = [description]
    } else {
      let description = NSPersistentStoreDescription()
      description.url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.tomas.hltt")?.appendingPathComponent("HoelangTotTrein2.db")
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

extension AppDataStore {

  public func stations() -> Promise<[Station], Error> {
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

  public func findOrUpdate(stations: [Station]) -> Promise<Void, Error> {
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

  public func find(stationName: String) -> Promise<Station, Error> {
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

  public func find(stationCode: String) -> Promise<Station, Error> {
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

  public func find(inBounds bounds: Bounds) -> Promise<[Station], Error> {
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

  public func find(stationNameContains query: String) -> Promise<[Station], Error> {
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

extension AppDataStore {

  public func insertHistory(station: Station, historyType: HistoryType) -> Promise<Void, Error> {
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

  public func mostUsedStations() -> Promise<[Station], Error> {
    return fetchMostUsedDict()
      .flatMap { stationCodes in
        whenAll(stationCodes.map({ (code, _) in
          self.find(stationCode: code)
        }))
      }
  }
}
 extension History {
  var historyType: HistoryType! {
    get {
      return HistoryType(rawValue: type!.intValue)
    }
    set {
      type = newValue!.rawValue as NSNumber
    }
  }
 }
