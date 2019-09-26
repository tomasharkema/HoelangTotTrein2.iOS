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
import Bindable
#if canImport(API)
import API
#endif

 public class AppDataStore: DataStore {
  
  let defaultKeepDepartedAdvice: Bool
  fileprivate let persistentContainer: NSPersistentContainer

  public init(useInMemoryStore: Bool = false, defaultKeepDepartedAdvice: Bool) {
    self.defaultKeepDepartedAdvice = defaultKeepDepartedAdvice
    #if os(watchOS)
    let bundleIdentifier = "io.harkema.HoelangTotTreinCoreWatch"
    #else
    let bundleIdentifier = "io.harkema.HoelangTotTreinCore"
    #endif

    guard let url = Bundle(identifier: bundleIdentifier)?.url(forResource: "HoelangTotTrein2", withExtension: "momd"),
      let model = NSManagedObjectModel(contentsOf: url)
      else {
        assertionFailure("NO MODEL")
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
        assertionFailure(error.localizedDescription)
      }
    }
  }
}

// Stations

extension Station {
  init?(record: StationRecord) {
    guard let name = record.name,
      let nameKort = record.nameKort,
      let nameMiddle = record.nameMiddle,
      let code = record.code,
      let land = record.land,
      let lat = record.lat?.doubleValue,
      let lng = record.lon?.doubleValue,
      let radius = record.radius?.doubleValue,
      let naderenRadius = record.naderenRadius?.doubleValue,
      let synoniemen = record.synoniemen as? [String],
      let uiccode = record.uicCode
      else {
        return nil
      }

    self.init(
      name: name,
      nameMiddle: nameMiddle,
      nameKort: nameKort,
      code: code,
      land: land,
      lat: lat,
      lng: lng,
      type: record.type,
      radius: radius,
      naderenRadius: naderenRadius,
      synoniemen: synoniemen,
      uiccode: uiccode
    )
  }
}

extension AppDataStore {

  public func stations() -> Promise<[Station], Error> {
    let promiseSource = PromiseSource<[Station], Error>()

    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
      do {
        promiseSource.resolve(try context.fetch(fetchRequest).compactMap({ Station(record: $0)}))
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
        
        let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(StationRecord.uicCode), NSNull())
        for station in try context.fetch(fetchRequest) {
          context.delete(station)
        }
        try context.save()
        
        for station in stations {
          
          let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
          fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(StationRecord.uicCode), station.UICCode.rawValue)
          
          let stationRecords = try context.fetch(fetchRequest)
          
          if stationRecords.count > 1 {
            for stationRecord in stationRecords {
              context.delete(stationRecord)
            }
          }
          
          if let stationRecord = try context.fetch(fetchRequest).first {
            stationRecord.name = station.name
            stationRecord.nameKort = station.namen.kort
            stationRecord.nameMiddle = station.namen.middel
            stationRecord.code = station.code.rawValue
            stationRecord.land = station.land
            stationRecord.lat = station.coords.lat as NSNumber
            stationRecord.lon = station.coords.lng as NSNumber
            stationRecord.type = station.type?.rawValue
            stationRecord.radius = station.radius as NSNumber
            stationRecord.naderenRadius = station.naderenRadius as NSNumber
            stationRecord.synoniemen = station.synoniemen as NSArray
            stationRecord.uicCode = station.UICCode.rawValue
          } else {
            let newStation = StationRecord(context: context)
            newStation.name = station.name
            newStation.nameKort = station.namen.kort
            newStation.nameMiddle = station.namen.middel
            newStation.code = station.code.rawValue
            newStation.land = station.land
            newStation.lat = station.coords.lat as NSNumber
            newStation.lon = station.coords.lng as NSNumber
            newStation.type = station.type?.rawValue
            newStation.radius = station.radius as NSNumber
            newStation.naderenRadius = station.naderenRadius as NSNumber
            newStation.synoniemen = station.synoniemen as NSArray
            newStation.uicCode = station.UICCode.rawValue
          }
        }

        try context.save()
        promiseSource.resolve(())
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
      fetchRequest.predicate = NSPredicate(format: "%K ==[c] %@", #keyPath(StationRecord.name), stationName)

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

  public func find(stationCode: StationCode) -> Promise<Station, Error> {
    let promiseSource = PromiseSource<Station, Error>()

    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "%K ==[c] %@", #keyPath(StationRecord.code), stationCode.rawValue)

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

  public func find(uicCode: UicCode) -> Promise<Station, Error> {
    let promiseSource = PromiseSource<Station, Error>()
    
    persistentContainer.performBackgroundTask { context in
      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "%K ==[c] %@", #keyPath(StationRecord.uicCode), uicCode.rawValue)
      
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
        promiseSource.resolve(try context.fetch(fetchRequest).compactMap { Station(record: $0) })
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
      fetchRequest.predicate = NSPredicate(format: "%K CONTAINS[cd] %@ OR %K ==[cd] %@", #keyPath(StationRecord.name), query, #keyPath(StationRecord.code), query)
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
      
      do {
        promiseSource.resolve(try context.fetch(fetchRequest).compactMap { Station(record: $0) })
      } catch {
        promiseSource.reject(error)
      }
    }
    return promiseSource.promise
  }
}

// History

extension AppDataStore {

  public func insertHistory(stationCode: UicCode, historyType: HistoryType) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()
    persistentContainer.performBackgroundTask { context in

      let fetchRequest: NSFetchRequest<StationRecord> = StationRecord.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "%K ==[c] %@", #keyPath(StationRecord.uicCode), stationCode.rawValue)

      do {
        let history = History(context: context)
        history.uicCode = stationCode.rawValue
        history.date = Date()
        history.historyType = historyType

        try context.save()
        promiseSource.resolve(())
      } catch {
        promiseSource.reject(error)
      }
    }
    return promiseSource.promise
  }

  private func fetchMostUsedDict() -> Promise<[(UicCode, Int)], Error> {
    let promiseSource = PromiseSource<[(UicCode, Int)], Error>()

    persistentContainer.performBackgroundTask { context in
      let stationCodeKeyPath = #keyPath(History.uicCode)
      guard let entity = NSEntityDescription.entity(forEntityName: "History", in: context),
        let stationCode = entity.attributesByName[stationCodeKeyPath] else {
        promiseSource.reject(DataStoreError.notFound)
        return
      }

      let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest<NSDictionary>(entityName: "History")
      fetchRequest.resultType = .dictionaryResultType
      fetchRequest.propertiesToGroupBy = [#keyPath(History.uicCode)]

      let countExpression = NSExpressionDescription()
      countExpression.name = "count"
      countExpression.expressionResultType = .integer64AttributeType
      let stationCodeExpression = NSExpression(forKeyPath: #keyPath(History.uicCode))
      countExpression.expression = NSExpression(forFunction: "count:", arguments: [stationCodeExpression])

      fetchRequest.propertiesToFetch = [stationCode, countExpression]

      do {
        let result = try context.fetch(fetchRequest)
        guard let results = result as? [[String: Any]] else {
          throw DataStoreError.notFound
        }

        let arr = results
          .compactMap { dict -> (UicCode, Int)? in
            guard let code = dict["uicCode"] as? String,
              let count = dict["count"] as? Int
              else { return nil }

            return (UicCode(rawValue: code), count)
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
        whenAll(stationCodes.map({ let (code, _) = $0;
          return self.find(uicCode: code)
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
