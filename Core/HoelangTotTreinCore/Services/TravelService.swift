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
#if os(watchOS)
import HoelangTotTreinAPIWatch
#elseif os(iOS)
import HoelangTotTreinAPI
import WatchConnectivity
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
  private let queue = DispatchQueue(label: "nl.tomasharkema.TravelService")
  private let apiService: ApiService
  private let locationService: LocationService
  private let dataStore: DataStore
  private let scheduler: SchedulerType

  #if os(iOS)
  let session = WCSession.default
  #endif

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

  private var timer: Timer?
  private var departureTimer: Timer?

  public init(apiService: ApiService, locationService: LocationService, dataStore: DataStore) {
    self.apiService = apiService
    self.locationService = locationService
    self.dataStore = dataStore
    self.scheduler = ConcurrentDispatchQueueScheduler(queue: self.queue)

    super.init()

    currentAdviceObservable = currentAdviceVariable.asObservable()
    currentAdvicesObservable = currentAdvicesVariable.asObservable()
    stationsObservable = stationsVariable.asObservable()
    firstAdviceRequestObservable = firstAdviceRequestVariable.asObservable()
    nextAdviceObservable = nextAdviceVariable.asObservable()
    currentAdviceOnScreenObservable = currentAdviceOnScreenVariable.asObservable()
    mostUsedStationsObservable = mostUsedStationsVariable.asObservable()
    
    #if os(iOS)
    NotificationCenter.default.addObserver(self, selector: #selector(startTimer), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(stopTimer), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    #endif
  }
  
  public func attach() {
    #if os(iOS)
    session.delegate = self
    session.activate()
    #endif

    _ = firstAdviceRequestObservable.observeOn(scheduler).subscribe(onNext: { adviceRequest in
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
      .observeOn(scheduler)
      .filterOptional()
      .throttle(3, scheduler: scheduler)
      .subscribe(onNext: { advice in

        self.startDepartureTimer(for: advice.vertrek.actualDate.timeIntervalSince(Date()))

        #if os(iOS)
        self.session.sendEvent(TravelEvent.currentAdviceChange(identifier: advice.identifier(), fromCode: advice.request.from, toCode: advice.request.to))
        let complicationUpdate = self.session.transferCurrentComplicationUserInfo(["delay": advice.vertrekVertraging ?? "+ 1 min"])
        print(complicationUpdate)
        #endif
      })

    _ = currentAdvicesObservable.asObservable().observeOn(scheduler).subscribe(onNext: { advices in

      guard case .loaded(let advices) = advices else {
        return
      }

      let element = advices.enumerated()
        .first { $0.element.identifier() == self.dataStore.currentAdviceIdentifier }?
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

  @objc public func startTimer() {
    guard timer == nil else {
      return
    }

    timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(tick), userInfo: "normal", repeats: true)
    tick()
  }

  public func startDepartureTimer(for time: TimeInterval) {
    guard time > 1 else {
      return
    }

    departureTimer?.invalidate()
    departureTimer = Timer.scheduledTimer(timeInterval: time + 1, target: self, selector: #selector(tick), userInfo: "departure", repeats: false)
  }

  @objc public func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  @objc public func tick() {
    fetchCurrentAdvices(for: nil, shouldEmitLoading: false)
      .finallyResult {
        print("DID FINISH TICK has value \($0.value != nil)")
      }
  }

  public func fetchStations() -> Promise<Stations, Error> {
    return apiService.stations()
      .map { $0.stations.filter { $0.land == "NL" } }
      .then { stations in
        print("TravelService did fetch stations: \(stations.count)")
        if self.stationsVariable.value ?? [] != stations {
          self.stationsVariable.value = stations
        }
      }
  }

  func getCurrentAdviceRequest() -> Promise<AdviceRequest, Error> {
    let from: Promise<Station?, Error> = dataStore.fromStationCode.map {
      self.dataStore.find(stationCode: $0)
        .map { .some($0) }
    } ?? Promise(value: nil)

    let to: Promise<Station?, Error> = dataStore.toStationCode.map {
      self.dataStore.find(stationCode: $0)
        .map { .some($0) }
    } ?? Promise(value: nil)
    
    return whenBoth(from, to)
      .map {
        AdviceRequest(from: $0.0, to: $0.1)
      }
  }

  private func setCurrentAdviceRequest(_ adviceRequest: AdviceRequest, userInput: Bool) -> Promise<Void, Error> {
    let correctedAdviceRequest: Promise<AdviceRequest, Error> = getCurrentAdviceRequest()
      .map { previousAdviceRequest in
        if adviceRequest.from == adviceRequest.to && previousAdviceRequest.from == adviceRequest.from {
          return AdviceRequest(from: previousAdviceRequest.to, to: previousAdviceRequest.from)
        } else if adviceRequest.from == adviceRequest.to && previousAdviceRequest.to == adviceRequest.to {
          return AdviceRequest(from: previousAdviceRequest.to, to: previousAdviceRequest.from)
        } else {
          return adviceRequest
        }
      }

    correctedAdviceRequest
      .then { request in

        if userInput {
          self.dataStore.fromStationByPickerCode = request.from?.code
          self.dataStore.toStationByPickerCode = request.to?.code
        }

        if self.firstAdviceRequestVariable.value != request {
          self.firstAdviceRequestVariable.value = request
        }
      }

    let registerPromise: Promise<SuccessResult, Error> = correctedAdviceRequest
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
      .flatMap {
        self.setStation(state, station: $0, byPicker: byPicker)
      }
      .then { _ in
        print("TravelService did set station \(stationName)")
      }
      .trap {
        print("TravelService setStation did encounter error \($0)")
      }
  }

  public func setStation(_ state: PickerState, stationCode: String, byPicker: Bool = false) -> Promise<Void, Error> {
    return dataStore.find(stationCode: stationCode)
      .flatMap {
        self.setStation(state, station: $0, byPicker: byPicker)
      }
      .then { _ in
        print("TravelService did set station \(stationCode)")
      }
      .trap {
        print("TravelService setStation did encounter error \($0)")
      }
  }

  public func setStation(_ state: PickerState, station: Station, byPicker: Bool = false) -> Promise<Void, Error> {
    return getCurrentAdviceRequest()
      .flatMap { advice in
        let newAdvice: AdviceRequest
        switch state {
        case .from:
          newAdvice = advice.setFrom(station)
        case .to:
          newAdvice = advice.setTo(station)
        }
        return self.setCurrentAdviceRequest(newAdvice, userInput: byPicker)
      }
  }

  private func fetchCurrentAdvices(for adviceRequest: AdviceRequest? = nil, shouldEmitLoading: Bool) -> Promise<AdvicesResult, Error> {
    if shouldEmitLoading {
      currentAdvicesVariable.value = .loading
    }

    return (adviceRequest.map { Promise(value: $0) } ?? getCurrentAdviceRequest())
      .flatMap { self.apiService.advices($0) }
      .then { advicesResult in
        print("TravelService fetchCurrentAdvices \(advicesResult.advices.count)")
        self.notifyOfNewAdvices(advicesResult.advices)
      }.trap { error in
        print(error)
      }
  }

  fileprivate func notifyOfNewAdvices(_ advices: Advices) {
    let keepDepartedAdvice = dataStore.keepDepartedAdvice
    let currentAdviceIdentifier = dataStore.currentAdviceIdentifier
    let advices = advices.filter {
      $0.isOngoing || (keepDepartedAdvice && $0.identifier() == currentAdviceIdentifier)
    }

    currentAdvicesVariable.value = .loaded(value: advices)

    let firstAdvice = advices.first { $0.identifier() == self.dataStore.currentAdviceIdentifier } 
    if let firstAdvice = firstAdvice ?? advices.first {
      currentAdviceVariable.value = firstAdvice
    }
    if let secondAdvice = advices.dropFirst().first {
      nextAdviceVariable.value = secondAdvice
    }
  }

  private func sortCloseLocations(_ center: CLLocation, stations: [Station]) -> [Station] {
    assert(!Thread.isMainThread, "prolly no good idea to call this from main thread")
    return stations.sorted { lhs, rhs in
      lhs.coords.location.distance(from: center) < rhs.coords.location.distance(from: center)
    }
  }

  public func getCloseStations() -> Promise<[Station], Error> {
    return locationService.currentLocation()
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
      .flatMap { let (stations, currentAdvice) = $0;
        guard let station = stations.first else {
          return Promise(error: TravelServiceError.notChanged)
        }

        return self.setCurrentAdviceRequest(currentAdvice.setFrom(station), userInput: true)
      }
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
    dataStore.currentAdviceIdentifier = advice?.identifier()
    currentAdviceOnScreenVariable.value = advice
  }

  public func setCurrentAdviceOnScreen(adviceIdentifier: String?) {
    dataStore.currentAdviceIdentifier = adviceIdentifier

    queue.async {
      let advice = self.dataStore.persistedAdvices?.first { $0.identifier() == adviceIdentifier }
      self.currentAdviceOnScreenVariable.value = advice
    }
  }

  func setMostUsedStations(stations: [Station]) {
    mostUsedStationsVariable.value = stations
  }

  public func find(stationNameContains: String) -> Promise<[Station], Error> {
    return dataStore.find(stationNameContains: stationNameContains)
  }

  public func find(stationCode: String) -> Promise<Station, Error> {
    return dataStore.find(stationCode: stationCode)
  }
}

#if os(iOS)

extension TravelService: WCSessionDelegate {
  public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    /* stub */
  }

  public func sessionDidBecomeInactive(_ session: WCSession) {
    /* stub */
  }

  public func sessionDidDeactivate(_ session: WCSession) {
    /* stub */
  }

  public func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {

    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(currentAdviceOnScreenVariable.value) else {
      return
    }

    replyHandler(data)
  }

  public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    print("didReceiveApplicationContext: \(applicationContext)")
  }
}
#endif
