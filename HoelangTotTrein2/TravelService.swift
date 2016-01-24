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

struct AdviceRequest: Equatable {
  let from: Station?
  let to: Station?

  func setFrom(from: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }

  func setTo(to: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }
}

func ==(lhs: AdviceRequest, rhs: AdviceRequest) -> Bool {
  return lhs.from == rhs.from && lhs.to == rhs.to
}

class TravelService: NSObject {
  let queue = dispatch_queue_create("nl.tomasharkema.TravelService", DISPATCH_QUEUE_SERIAL)
  private let apiService: ApiService
  private let locationService: LocationService

  private var currentAdviceRequestSubscription: ObservableSubject<AdviceRequest>!
  private var geofenceSubscription: ObservableSubject<GeofenceModel>!

  init(apiService: ApiService, locationService: LocationService) {
    self.apiService = apiService
    self.locationService = locationService
  }

  func attach() {
    currentAdviceRequestSubscription = currentAdviceRequest.subscribe { [weak self] adviceRequest in
      UserDefaults.fromStationCode = adviceRequest.from?.code
      UserDefaults.toStationCode = adviceRequest.to?.code

      self?.fetchCurrentAdvices(adviceRequest)
    }

    geofenceSubscription = App.geofenceService.geofenceObservable.subscribe { [weak self] geofence in
      switch geofence.type {
      case .Overstap, .End:
        self?.setStation(.From, station: geofence.station)

      default:
        break
      }
    }

    currentAdviceRequest.next(getCurrentAdvice())
  }

  deinit {
    currentAdviceRequest.unsubscribe(currentAdviceRequestSubscription)
    App.geofenceService.geofenceObservable.unsubscribe(geofenceSubscription)
  }

  let currentAdviceObservable = Observable<Advice>()
  let currentAdvicesObservable = Observable<Advices>()
  let stationsObservable = Observable<Stations>()
  let currentAdviceRequest = Observable<AdviceRequest>()
  let nextAdviceObservable = Observable<Advice>()

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
    }.trap { error in
      print(error)
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

  func setCurrentAdviceRequest(adviceRequest: AdviceRequest, userInput: Bool) {
    let correctedAdviceRequest: AdviceRequest
    if let pickerFrom = UserDefaults.fromStationByPickerCode,
      pickerTo = UserDefaults.toStationByPickerCode,
      from = Station.fromCode(pickerFrom), to = Station.fromCode(pickerTo) where !userInput && pickerTo == adviceRequest.from?.code {
        UserDefaults.fromStationByPickerCode = to.code
        UserDefaults.toStationByPickerCode = from.code
        correctedAdviceRequest = AdviceRequest(from: to, to: from)
    } else {
      correctedAdviceRequest = adviceRequest
    }

    if let from = correctedAdviceRequest.from, to = correctedAdviceRequest.to {
      App.apiService.registerForNotification(UserDefaults.userId, from: from, to: to).then {
        print($0)
      }.trap {
        print($0)
      }
    }
    currentAdviceRequest.next(correctedAdviceRequest)
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

    setCurrentAdviceRequest(newAdvice, userInput: byPicker)
  }

  func fetchCurrentAdvices(adviceRequest: AdviceRequest) {
    apiService.advices(adviceRequest).then { [weak self] advicesResult in
      let advices = advicesResult.advices.filter {
        $0.isOngoing
      }

      if let firstAdvice = advices.first {
        self?.currentAdviceObservable.next(firstAdvice)
      }
      if let secondAdvice = advices[safe: 1] {
        self?.nextAdviceObservable.next(secondAdvice)
      }
      self?.currentAdvicesObservable.next(advices)
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
      if let stations = try? CDK.mainThreadContext.find(StationRecord.self, predicate: predicate, sortDescriptors: nil, limit: nil) {
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

            service.setCurrentAdviceRequest(newAdvice, userInput: true)
          }
        }.trap { error in
          print(error)
        }
      }
    }
  }

  func switchFromTo() {
    let currentAdvice = getCurrentAdvice()
    setCurrentAdviceRequest(AdviceRequest(from: currentAdvice.to, to: currentAdvice.from), userInput: true)
  }

}