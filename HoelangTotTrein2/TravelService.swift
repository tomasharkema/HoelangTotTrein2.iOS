//
//  TravelService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import CoreDataKit
import CoreLocation
import Promissum

struct AdviceRequest {
  let from: Station?
  let to: Station?

  func setFrom(from: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }

  func setTo(to: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }
}

class TravelService: NSObject {
  let queue = dispatch_queue_create("nl.tomasharkema.TravelService", DISPATCH_QUEUE_SERIAL)
  private let apiService: ApiService
  private let locationService: LocationService

  private var currentAdviceRequestSubscription: ObservableSubject<AdviceRequest>!

  init(apiService: ApiService, locationService: LocationService) {
    self.apiService = apiService
    self.locationService = locationService
    super.init()

    currentAdviceRequestSubscription = currentAdviceRequest.subscribe { [weak self] adviceRequest in
      UserDefaults.fromStationCode = adviceRequest.from?.code
      UserDefaults.toStationCode = adviceRequest.to?.code

      self?.fetchCurrentAdvices(adviceRequest)
    }

    currentAdviceRequest.next(getCurrentAdvice())
  }

  deinit {
    currentAdviceRequest.unsubscribe(currentAdviceRequestSubscription)
  }

  let currentAdviceObservable = Observable<Advice>()
  let currentAdvicesObservable = Observable<[Advice]>()
  let stationsObservable = Observable<[Station]>()
  let currentAdviceRequest = Observable<AdviceRequest>()

  var timer: NSTimer?

  func startTimer() {
    timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "tick:", userInfo: nil, repeats: true)
    tick(timer!)
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  func tick(timer: NSTimer) {
    fetchCurrentAdvices(getCurrentAdvice())
  }

  func fetchStations() {
    App.apiService.stations().then { [weak self] stations in
      self?.stationsObservable.next(stations.stations)
    }
  }

  func getCurrentAdvice(context: NSManagedObjectContext = CDK.mainThreadContext) -> AdviceRequest {
    let from: Station?
    if let fromCode = UserDefaults.fromStationCode {
      from = Station.fromCode(fromCode, context: context)
    } else {
      from = nil
    }
    let to: Station?
    if let toCode = UserDefaults.toStationCode {
      to = Station.fromCode(toCode, context: context)
    } else {
      to = nil
    }

    return AdviceRequest(from: from, to: to)
  }

  func setCurrentAdviceRequest(adviceRequest: AdviceRequest) {
    if let from = adviceRequest.from, to = adviceRequest.to {
      App.apiService.registerForNotification(UserDefaults.userId, from: from, to: to).then {
        print($0)
      }.trap {
        print($0)
      }
    }
    currentAdviceRequest.next(adviceRequest)
  }

  func setStation(state: PickerState, station: Station, byPicker: Bool = false) {
    let advice = getCurrentAdvice()
    let newAdvice: AdviceRequest
    switch state {
    case .From:
      newAdvice = advice.setFrom(station)
    case .To:
      newAdvice = advice.setTo(station)
    }

    if byPicker {
      switch state {
      case .From:
        UserDefaults.fromStationByPickerCode = station.code
      case .To:
        UserDefaults.toStationByPickerCode = station.code
      }
    }

    setCurrentAdviceRequest(newAdvice)
  }

  func fetchCurrentAdvices(adviceRequest: AdviceRequest) {
    apiService.advices(adviceRequest).then { [weak self] advices in
      if let firstAdvice = advices.advices.first {
        self?.currentAdviceObservable.next(firstAdvice)
      }
      self?.currentAdvicesObservable.next(advices.advices)
    }
  }

  func stationByCode(code: String, context: NSManagedObjectContext = CDK.mainThreadContext) -> Station? {
    guard let stationRecord = try? context.findFirst(StationRecord.self, predicate: NSPredicate(format: "code = %@", code)) else {
      return nil
    }

    return stationRecord?.toStation()
  }

  func sortCloseLocations(center: CLLocation, stations: [StationRecord]) -> [StationRecord] {
    return stations.sort { lhs, rhs in
      lhs.toStation().coords.location.distanceFromLocation(center) < rhs.toStation().coords.location.distanceFromLocation(center)
    }
  }

  func getCloseStations() -> Promise<[StationRecord], ErrorType> {
    return locationService.currentLocation().flatMap { currentLocation in
      let circularRegionBounds = CLCircularRegion(center: currentLocation.coordinate, radius: 0.1, identifier:"").bounds

      let predicate = NSPredicate(format: "lat > %f AND lat < %f AND lon > %f AND lon < %f", circularRegionBounds.latmin, circularRegionBounds.latmax, circularRegionBounds.lonmin, circularRegionBounds.lonmax)
      if let stations = try? CDK.backgroundContext.find(StationRecord.self, predicate: predicate, sortDescriptors: nil, limit: nil) {
        return Promise(value: self.sortCloseLocations(currentLocation, stations: stations))
      }

      return Promise(error: NSError(domain: "HLTT", code: 500, userInfo: nil))
    }
  }

  func travelFromCurrentLocation() {
    dispatch_async(queue) { [weak self] in
      if let service = self {
        service.getCloseStations().map { (stationRecords: [StationRecord]) in
          stationRecords.map { (stationRecord: StationRecord) in
            stationRecord.toStation()
          }
        }.then {
          if let station = $0.first {
            let currentAdvice = service.getCurrentAdvice(CDK.backgroundContext)

            let newAdvice: AdviceRequest
            if currentAdvice.to == station {
              newAdvice = AdviceRequest(from: currentAdvice.to, to: currentAdvice.from)
            } else {
              newAdvice = AdviceRequest(from: station, to: currentAdvice.to)
            }

            service.setCurrentAdviceRequest(newAdvice)
          }
        }.trap { error in
          print(error)
        }
      }
    }
  }

  func switchFromTo() {
    let currentAdvice = getCurrentAdvice()
    setCurrentAdviceRequest(AdviceRequest(from: currentAdvice.to, to: currentAdvice.from))
  }

}