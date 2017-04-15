//
//  Advice+iOS.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import HoelangTotTreinAPI

extension Station {
//  func getStationRecord(_ context: NSManagedObjectContext) -> StationRecord? {
//    do {
//      return try context.findFirst(StationRecord.self, predicate: NSPredicate(format: "code = %@", code))
//    } catch {
//      print(error)
//      return nil
//    }
//  }
//
//  static func fromCode(_ code: String, context: NSManagedObjectContext = CDK.mainThreadContext) -> Station? {
//    let toPredicate = NSPredicate(format: "code = %@", code)
//    do {
//      return try context.findFirst(StationRecord.self, predicate: toPredicate)?.toStation()
//    } catch {
//      return nil
//    }
//  }
}

extension Advice {
//  var mostSignificantStop: Station? {
//    let stations = reisDeel.lazy.map { deel in
//      return deel.stops[1..<deel.stops.count-1].map { (stop: Stop) -> Station?? in
//        let predicate = NSPredicate(format: "name = %@", stop.name)
//
//        return try? CDK.mainThreadContext.findFirst(StationRecord.self, predicate: predicate, sortDescriptors: nil, offset: nil)?.toStation()
//      }
//      }.flatten()
//
//    let optionalStations = stations.flatMap { (element: Station??) -> Station? in
//      if element != nil {
//        if element! != nil {
//          return element!
//        }
//      }
//
//      return nil
//    }
//
//    let filteredStations = optionalStations
//      .filter { $0.type != .StoptreinStation }
//      .sorted { $0.type.score > $1.type.score }
//
//    return filteredStations.first
//  }


  var smallExtraMessage: String {

    if let _ = reisDeel.first, reisDeel.count == 1 {
      return ""
    }

    return "" //mostSignificantStop?.code ?? ""
  }

  var extraMessage: String {

    if let firstReisDeel = reisDeel.first, reisDeel.count == 1 {
      return firstReisDeel.vervoerType
    }

    return "" //mostSignificantStop.map { "Via: \($0.name)" } ?? ""
  }

  var stepsMessage: String {
    return reisDeel.reduce("")
    { (prev, item) in
      if let from = item.stops.first, let to = item.stops.last {
        let fromTimeString = from.timeDate.toString(format: .custom("HH:mm"))
        let toTimeString = to.timeDate.toString(format: .custom("HH:mm"))
        //👉
        return prev + "\(from.name) \(fromTimeString) (\(from.spoor ?? "")) → \(to.name) \(toTimeString) (\(to.spoor ?? ""))\n\n"
      }
      return prev
    }
  }

  var stepModels: [StepViewModel] {
    return reisDeel.flatMap { item in
      if let from = item.stops.first, let to = item.stops.last {
        return StepViewModel(fromStation: from.name, toStation: to.name, fromSpoor: from.spoor ?? "", toSpoor: to.spoor ?? "", fromTime: from.timeDate.toString(format: .custom("HH:mm")), toTime: to.timeDate.toString(format: .custom("HH:mm")))
      }
      return nil
    }
  }
  
}
