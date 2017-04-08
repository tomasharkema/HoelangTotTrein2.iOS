//
//  TravelService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
//import CoreData
import CoreLocation
import Promissum
import RxSwift
//import WatchConnectivity
#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

enum TravelServiceError: Error {
  case notChanged
}

public enum LoadingState<ValueType> {
  case loaded(value: ValueType)
  case loading

  public var value: ValueType? {
    switch self {
    case .loading:
      return nil
    case .loaded(let value):
      return value
    }
  }
}

public class TravelService: NSObject {
  let queue = DispatchQueue(label: "nl.tomasharkema.TravelService", attributes: [])
  fileprivate let apiService: ApiService
  fileprivate let locationService: LocationService
  private let dataStore: DataStore

//  let session = WCSession.default()

  private let currentAdviceVariable = Variable<Advice?>(nil)
  public private(set) var currentAdviceObservable: Observable<Advice?>!

  private let currentAdvicesVariable = Variable<LoadingState<Advices>>(.loading)
  public private(set) var currentAdvicesObservable: Observable<LoadingState<Advices>>!

  private let stationsVariable = Variable<Stations?>(nil)
  public private(set) var stationsObservable: Observable<Stations?>!

  private let firstAdviceRequestVariable = Variable<AdviceRequest?>(nil)
  public private(set) var firstAdviceRequestObservable: Observable<AdviceRequest?>!

  private let nextAdviceVariable = Variable<Advice?>(nil)
  public private(set) var nextAdviceObservable: Observable<Advice?>!

  fileprivate let currentAdviceOnScreenVariable = Variable<Advice?>(nil)
  public private(set) var currentAdviceOnScreenObservable: Observable<Advice?>!

  private let mostUsedStationsVariable = Variable<[Station]>([])
  public private(set) var mostUsedStationsObservable: Observable<[Station]>!

  var timer: Timer?
  var departureTimer: Timer?

  public init(apiService: ApiService, locationService: LocationService, dataStore: DataStore) {
    self.apiService = apiService
    self.locationService = locationService
    self.dataStore = dataStore

    super.init()

    currentAdviceObservable = currentAdviceVariable.asObservable()
    currentAdvicesObservable = currentAdvicesVariable.asObservable()
    stationsObservable = stationsVariable.asObservable()
    firstAdviceRequestObservable = firstAdviceRequestVariable.asObservable()
    nextAdviceObservable = nextAdviceVariable.asObservable()
    currentAdviceOnScreenObservable = currentAdviceOnScreenVariable.asObservable()
    mostUsedStationsObservable = mostUsedStationsVariable.asObservable()
    
    NotificationCenter.default.addObserver(self, selector: #selector(startTimer), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(stopTimer), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
  }
  
  public func attach() {

//    session.delegate = self
//    session.activate()

    _ = firstAdviceRequestObservable.subscribe(onNext: { adviceRequest in
      guard let adviceRequest = adviceRequest else {
        return
      }

      if let from = adviceRequest.from {
        self.dataStore.fromStationCode = from.code
      }

      if let to = adviceRequest.to {
        self.dataStore.toStationCode = to.code
      }

      _ = self.fetchCurrentAdvices(for: adviceRequest, shouldEmitLoading: true)
    })

//    _ = App.geofenceService.geofenceObservable?.asObservable()
//      .observeOn(MainScheduler.asyncInstance)
//      .filter { $0.type != .tussenStation }
//      .subscribe(onNext: { geofence in
//        _ = self.setStation(.from, stationName: geofence.stationName)
//      })
//
//    _ = stationsObservable.asObservable()
//      .single()
//      .subscribe(onNext: { _ in
//        self.getCurrentAdviceRequest()
//          .dispatch(on: self.queue)
//          .then { adviceRequest in
//            if self.firstAdviceRequestVariable.value != adviceRequest {
//              self.firstAdviceRequestVariable.value = adviceRequest
//            }
//
//            if let advicesAndRequest = UserDefaults.persistedAdvicesAndRequest, advicesAndRequest.adviceRequest == adviceRequest {
//              self.notifyOfNewAdvices(advicesAndRequest.advices)
//            }
//          }
//      })

    _ = currentAdviceOnScreenVariable.asObservable()
      .filterOptional()
      .throttle(3, scheduler: MainScheduler.asyncInstance)
      .subscribe(onNext: { advice in

        self.startDepartureTimer(for: advice.vertrek.actualDate.timeIntervalSince(Date()))

//        self.session.sendEvent(TravelEvent.currentAdviceChange(hash: advice.hashValue))
//        let complicationUpdate = self.session.transferCurrentComplicationUserInfo(["delay": advice.vertrekVertraging ?? "+ 1 min"])
//        print(complicationUpdate)
      })

    _ = currentAdvicesObservable.asObservable().subscribe(onNext: { advices in

      guard case .loaded(let advices) = advices else {
        return
      }

      let element = advices.enumerated()
        .first { $0.element.hashValue == self.dataStore.currentAdviceHash }?
        .element ?? advices.first

      self.currentAdviceOnScreenVariable.value = element
    })

    self.getCurrentAdviceRequest()
      .dispatch(on: self.queue)
      .then { adviceRequest in
        if self.firstAdviceRequestVariable.value != adviceRequest {
          self.firstAdviceRequestVariable.value = adviceRequest
        }

        if let advicesAndRequest = self.dataStore.persistedAdvicesAndRequest, advicesAndRequest.adviceRequest == adviceRequest {
          self.notifyOfNewAdvices(advicesAndRequest.advices)
        }
      }
  }

  public func startTimer() {
    guard timer == nil else {
      return
    }

    timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(tick), userInfo: nil, repeats: true)

    tick()
  }

  public func startDepartureTimer(for time: TimeInterval) {
    guard departureTimer == nil, time > 1 else {
      return
    }

    departureTimer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
  }

  public func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  public func tick() {
    getCurrentAdviceRequest()
      .dispatch(on: queue)
      .then {
        _ = self.fetchCurrentAdvices(for: $0, shouldEmitLoading: false)
      }
  }

  public func fetchStations() -> Promise<Stations, Error> {
    return apiService.stations()
      .dispatch(on: queue)
      .map {
        $0.stations.filter {
          $0.land == "NL"
        }
      }
      .then { stations in
        print("TravelService did fetch stations: \(stations.count)")
        if self.stationsVariable.value != stations {
          self.stationsVariable.value = stations
        }
      }
      .trap { error in
        print(error)
      }
  }

  func getCurrentAdviceRequest() -> Promise<AdviceRequest, Error> {
    let from: Promise<Station?, Error> = dataStore.fromStationCode.map {
      self.dataStore.find(stationCode: $0)
        .dispatch(on: queue)
        .map {
          .some($0)
        }
    } ?? Promise(value: nil)

    let to: Promise<Station?, Error> = dataStore.toStationCode.map {
      self.dataStore.find(stationCode: $0)
        .dispatch(on: queue)
        .map {
          .some($0)
        }
    } ?? Promise(value: nil)
    
    return whenBoth(from, to)
      .dispatch(on: queue)
      .map {
        AdviceRequest(from: $0.0, to: $0.1)
      }
  }

  func setCurrentAdviceRequest(_ adviceRequest: AdviceRequest, userInput: Bool) -> Promise<Void, Error> {

    let correctedAdviceRequest: Promise<AdviceRequest, Error>
    if let pickerFrom = dataStore.fromStationByPickerCode,
      let pickerTo = dataStore.toStationByPickerCode,
      pickerTo == adviceRequest.from?.code {

      correctedAdviceRequest = whenBoth(dataStore.find(stationCode: pickerFrom), dataStore.find(stationCode: pickerTo))
        .then {
          self.dataStore.fromStationByPickerCode = $0.1.code
          self.dataStore.toStationByPickerCode = $0.0.code
        }
        .map {
          AdviceRequest(from: $0.1, to: $0.0)
        }
    } else {
      correctedAdviceRequest = Promise(value: adviceRequest)
    }

    correctedAdviceRequest
      .dispatch(on: queue)
      .then { request in
        if self.firstAdviceRequestVariable.value != request {
          self.firstAdviceRequestVariable.value = request
        }
      }

    let registerPromise: Promise<SuccessResult, Error> = correctedAdviceRequest
      .dispatch(on: queue)
      .flatMap { advice in
        guard let from = advice.from, let to = advice.to else {
          return Promise(error: TravelServiceError.notChanged)
        }
        return self.apiService.registerForNotification(self.dataStore.userId, from: from, to: to)
      }

    return registerPromise.mapVoid()
  }
  
  public func setStation(_ state: PickerState, stationName: String, byPicker: Bool = false) -> Promise<Void, Error> {
    return dataStore.find(stationName: stationName)
      .dispatch(on: queue)
      .flatMap {
        self.setStation(state, station: $0)
      }
      .then {
        print("TravelService did set station \(stationName)")
      }
      .trap {
        print("TravelService setStation did encounter error \($0)")
      }
  }

  public func setStation(_ state: PickerState, station: Station, byPicker: Bool = false) -> Promise<Void, Error> {
    return getCurrentAdviceRequest()
      .dispatch(on: queue)
      .flatMap { advice in
        let newAdvice: AdviceRequest
        if advice.to == station {
          newAdvice = AdviceRequest(from: advice.to, to: advice.from)
        } else {
          switch state {
          case .from:
            newAdvice = advice.setFrom(station)
          case .to:
            newAdvice = advice.setTo(station)
          }
        }
        
        if byPicker {
          switch state {
          case .from:
            self.dataStore.fromStationByPickerCode = station.code
          case .to:
            self.dataStore.toStationByPickerCode = station.code
          }
        }

        return self.setCurrentAdviceRequest(newAdvice, userInput: byPicker)
      }
  }

  func fetchCurrentAdvices(for adviceRequest: AdviceRequest? = nil, shouldEmitLoading: Bool) -> Promise<AdvicesResult, Error> {
    if shouldEmitLoading {
      currentAdvicesVariable.value = .loading
    }

    return (adviceRequest.map { Promise(value: $0) } ?? getCurrentAdviceRequest())
      .dispatch(on: queue)
      .flatMap { self.apiService.advices($0) }
      .then { advicesResult in
        print("TravelService fetchCurrentAdvices \(advicesResult.advices.count)")
        self.notifyOfNewAdvices(advicesResult.advices)
      }.trap { error in
        print(error)
      }
  }

  fileprivate func notifyOfNewAdvices(_ advices: Advices) {
    let advices = advices.filter {
      return $0.isOngoing || $0.hashValue == self.dataStore.currentAdviceHash
    }

    if let firstAdvice = advices.first {
      if currentAdviceVariable.value != firstAdvice {
        currentAdviceVariable.value = firstAdvice
      }
    }
    if let secondAdvice = advices[safe: 1] {
      if nextAdviceVariable.value != secondAdvice {
        nextAdviceVariable.value = secondAdvice
      }
    }
    if currentAdvicesVariable.value.value != advices {
//      session.sendEvent(TravelEvent.advicesChange(advice: advices))
      currentAdvicesVariable.value = .loaded(value: advices)
    }
  }

  func sortCloseLocations(_ center: CLLocation, stations: [Station]) -> [Station] {
    return stations.sorted { lhs, rhs in
      lhs.coords.location.distance(from: center) < rhs.coords.location.distance(from: center)
    }
  }

  public func getCloseStations() -> Promise<[Station], Error> {
    return locationService.currentLocation()
      .dispatch(on: self.queue)
      .flatMap { currentLocation in
        let circularRegionBounds = CLCircularRegion(center: currentLocation.coordinate, radius: 0.1, identifier:"").bounds

        return self.dataStore.find(inBounds: circularRegionBounds)
          .dispatch(on: self.queue)
          .map { stations in
            self.sortCloseLocations(currentLocation, stations: stations)
          }
      }
  }

  public func travelFromCurrentLocation() -> Promise<Void, Error> {
    return whenBoth(getCloseStations(), getCurrentAdviceRequest())
      .dispatch(on: queue)
      .flatMap { (stations, currentAdvice) in
        guard let station = stations.first else {
          return Promise(error: TravelServiceError.notChanged)
        }

        let newAdvice: AdviceRequest
        if currentAdvice.to == station {
          newAdvice = AdviceRequest(from: currentAdvice.to, to: currentAdvice.from)
        } else {
          newAdvice = AdviceRequest(from: station, to: currentAdvice.to)
        }

        return self.setCurrentAdviceRequest(newAdvice, userInput: true)
      }
      .then { print($0) }.trap { print($0) }
  }

  public func switchFromTo() -> Promise<Void, Error> {
    return getCurrentAdviceRequest().flatMap { currentAdvice in
      self.setCurrentAdviceRequest(AdviceRequest(from: currentAdvice.to, to: currentAdvice.from), userInput: true)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  public func setCurrentAdviceOnScreen(advice: Advice?) {
    dataStore.currentAdviceHash = advice?.hashValue
    currentAdviceOnScreenVariable.value = advice
  }

  func setMostUsedStations(stations: [Station]) {
    mostUsedStationsVariable.value = stations
  }

  public func find(stationNameContains: String) -> Promise<[Station], Error> {
    return dataStore.find(stationNameContains: stationNameContains)
  }
}

//extension TravelService: WCSessionDelegate {
//  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//    /* stub */
//  }
//
//  func sessionDidBecomeInactive(_ session: WCSession) {
//    /* stub */
//  }
//
//  open func sessionDidDeactivate(_ session: WCSession) {
//    /* stub */
//  }
//
//  func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
//    guard let advice = currentAdviceOnScreenVariable.value?.encodeJson(), let data = jsonToNSData(advice) else {
//      return
//    }
//
//    replyHandler(data)
//  }
//
//  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
//    print("didReceiveApplicationContext: \(applicationContext)")
//  }
//}
