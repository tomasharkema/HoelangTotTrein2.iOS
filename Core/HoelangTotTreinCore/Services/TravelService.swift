//
//  TravelService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreLocation
import Promissum
//import RxSwift
import Bindable

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
  private let preferenceStore: PreferenceStore
  private let heartBeat: HeartBeat
  private var heartBeatToken: HeartBeat.Token?

  #if os(iOS)
  private let session = WCSession.default
  #endif

//  private let currentAdviceVariable = RxSwift.Variable<Advice?>(nil)
//  public private(set) var currentAdviceObservable: Observable<Advice?>!
//
//  private let currentAdvicesVariable = RxSwift.Variable<LoadingState<Advices>>(.loading)
//  public private(set) var currentAdvicesObservable: Observable<LoadingState<Advices>>!
//
//  private let firstAdviceRequestVariable = RxSwift.Variable<AdviceRequest?>(nil)
//  public private(set) var firstAdviceRequestObservable: Observable<AdviceRequest?>!
//
//  private let nextAdviceVariable = RxSwift.Variable<Advice?>(nil)
//  public private(set) var nextAdviceObservable: Observable<Advice?>!
//
//  fileprivate let currentAdviceOnScreenVariable = RxSwift.Variable<Advice?>(nil)
//  public private(set) var currentAdviceOnScreenObservable: Observable<Advice?>!
//
//  private let mostUsedStationsVariable = RxSwift.Variable<[Station]>([])
//  public private(set) var mostUsedStationsObservable: Observable<[Station]>!

//  private let currentAdviceRequestSource = Bindable.VariableSource<AdviceRequest>(value: AdviceRequest(from: nil, to: nil))
//  public let currentAdviceRequest: Bindable.Variable<AdviceRequest>

  private let currentAdvicesSource = VariableSource<LoadingState<Advices>>(value: .loading)
  public let currentAdvices: Variable<LoadingState<Advices>>

  private let currentAdviceOnScreenSource = VariableSource<Advice?>(value: nil)
  public let currentAdviceOnScreen: Variable<Advice?>

  private let pickedAdviceRequestSource = VariableSource(value: AdviceRequest(from: nil, to: nil))
  public let pickedAdviceRequest: Variable<AdviceRequest>

  private let mostUsedStationsSource = VariableSource(value: Stations())
  public let mostUsedStations: Variable<Stations>

  private let stationsSource = VariableSource(value: Stations())
  public let stations: Variable<Stations>

  public let currentAdvice: Variable<Advice?>

  public init(apiService: ApiService, locationService: LocationService, dataStore: DataStore, preferenceStore: PreferenceStore, heartBeat: HeartBeat) {
    self.apiService = apiService
    self.locationService = locationService
    self.dataStore = dataStore
    self.preferenceStore = preferenceStore
    self.heartBeat = heartBeat

    currentAdvices = currentAdvicesSource.variable
    currentAdviceOnScreen = currentAdviceOnScreenSource.variable
    pickedAdviceRequest = pickedAdviceRequestSource.variable
    mostUsedStations = mostUsedStationsSource.variable
    stations = stationsSource.variable

    currentAdvice = (currentAdvices && preferenceStore.currentAdviceIdentifier)
      .map { (loadedAdvices, adviceIdentifier) in
        switch loadedAdvices {
        case .loaded(let advices):
          let firstAdvice = advices.first { $0.identifier == adviceIdentifier }
          return firstAdvice ?? advices.first
        case .loading:
          return nil
        }
      }

    super.init()

    start()
  }

  var fromAndToCodePicked: (String?, String?) = (nil, nil) {
    didSet {
      let from: Promise<Station?, Error> = fromAndToCodePicked.0.map {
        self.dataStore.find(stationCode: $0)
          .map { .some($0) }
        } ?? Promise(value: nil)

      let to: Promise<Station?, Error> = fromAndToCodePicked.1.map {
        self.dataStore.find(stationCode: $0)
          .map { .some($0) }
        } ?? Promise(value: nil)

      whenBoth(from, to)
        .map {
          AdviceRequest(from: $0.0, to: $0.1)
        }
        .then { [pickedAdviceRequestSource] request in
          pickedAdviceRequestSource.value = request
        }
        .trap {
          print("fromAndToCodePicked error \($0)")
        }
    }
  }

  private func start() {
    heartBeatToken = heartBeat.register(type: .repeating(interval: 10)) { [weak self] _ in
      self?.tick()
    }

    bind(\.fromAndToCodePicked, to: preferenceStore.fromStationByPickerCode && preferenceStore.toStationByPickerCode)
  }
  
  public func attach() {
    #if os(iOS)
//      session.delegate = self
//      session.activate()
    #endif

//    _ = firstAdviceRequestObservable.observeOn(scheduler).subscribe(onNext: { adviceRequest in
//      guard let adviceRequest = adviceRequest else {
//        return
//      }
//
//      if let from = adviceRequest.from {
//        self.preferenceStore.setFromStationCode(code: from.code)
//      }
//
//      if let to = adviceRequest.to {
//        self.preferenceStore.setToStationCode(code: to.code)
//      }
//
//      _ = self.fetchCurrentAdvices(for: adviceRequest, shouldEmitLoading: true)
//    })

//    _ = stationsObservable.asObservable()
//      .single()
//      .subscribe(onNext: { [pickedAdviceRequest, preferenceStore] _ in
//
//        let adviceRequest = pickedAdviceRequest.value
//        if self.firstAdviceRequestVariable.value != adviceRequest {
//          self.firstAdviceRequestVariable.value = adviceRequest
//        }
//        if let advicesAndRequest = preferenceStore.persistedAdvicesAndRequest, advicesAndRequest.adviceRequest == adviceRequest {
//          self.notifyOfNewAdvices(advicesAndRequest.advices)
//        }
//      })

//    _ = currentAdviceOnScreenVariable.asObservable()
//      .observeOn(scheduler)
//      .filterOptional()
//      .throttle(3, scheduler: scheduler)
//      .subscribe(onNext: { advice in
//
////        self.startDepartureTimer(for: advice.vertrek.actual.timeIntervalSince(Date()))
//
//        #if os(iOS)
//          self.session.sendEvent(.currentAdviceChange(change: CurrentAdviceChangeData(identifier: advice.identifier(), fromCode: advice.request.from, toCode: advice.request.to)))
//          self.session.transferCurrentComplicationUserInfo(["delay": advice.vertrekVertraging ?? "+ 1 min"])
//        #endif
//      })
//
//    _ = currentAdvicesObservable.asObservable().observeOn(scheduler).subscribe(onNext: { advices in
//
//      guard case .loaded(let advices) = advices else {
//        return
//      }
//
//      let element = advices.enumerated()
//        .first { $0.element.identifier() == self.preferenceStore.currentAdviceIdentifier }?
//        .element ?? advices.first
//
//      self.currentAdviceOnScreenVariable.value = element
//    })

//    self.getCurrentAdviceRequest()
//      .dispatch(on: self.queue)
//      .then { adviceRequest in
//        if self.firstAdviceRequestVariable.value != adviceRequest {
//          self.firstAdviceRequestVariable.value = adviceRequest
//        }
//
//        if let advicesAndRequest = self.preferenceStore.persistedAdvicesAndRequest, advicesAndRequest.adviceRequest == adviceRequest {
//          self.notifyOfNewAdvices(advicesAndRequest.advices)
//        }
//      }
  }

  @objc public func tick() {
    fetchCurrentAdvices(for: nil, shouldEmitLoading: false)
      .finallyResult {
        print("\(Date()) DID FINISH TICK has value \($0.value != nil)")
      }
  }

  public func fetchStations() -> Promise<Stations, Error> {
    return apiService.stations()
      .mapError { $0 as Error }
      .map { $0.stations.filter { $0.land == "NL" } }
      .then { [stationsSource] stations in
        print("TravelService did fetch stations: \(stations.count)")
//        if self.stationsVariable.value ?? [] != stations {
//          self.stationsVariable.value = stations
//        }
        stationsSource.value = stations
      }
  }

  private func setCurrentAdviceRequest(_ adviceRequest: AdviceRequest) {

    let previousAdviceRequest = pickedAdviceRequest.value // TODO: currentAdviceRequest.value
    let adviceByPicker = pickedAdviceRequest.value

    let correctedAdviceRequest: AdviceRequest
    if adviceRequest.from == adviceRequest.to && previousAdviceRequest.from == adviceRequest.from {
      correctedAdviceRequest = AdviceRequest(from: previousAdviceRequest.to, to: previousAdviceRequest.from) // TODO: figure out this case
    } else if adviceRequest.from == adviceRequest.to && previousAdviceRequest.to == adviceByPicker.from {
      correctedAdviceRequest = AdviceRequest(from: adviceByPicker.from, to: adviceByPicker.to)
    } else if adviceRequest.from == adviceRequest.to && previousAdviceRequest.to == adviceRequest.to {
      correctedAdviceRequest = AdviceRequest(from: previousAdviceRequest.to, to: adviceByPicker.from ?? previousAdviceRequest.from)
    } else {
      correctedAdviceRequest = adviceRequest
    }

    preferenceStore.setFromStationByPickerCode(code: correctedAdviceRequest.from?.code)
    preferenceStore.setToStationByPickerCode(code: correctedAdviceRequest.to?.code)

//    if self.firstAdviceRequestVariable.value != correctedAdviceRequest {
//      self.firstAdviceRequestVariable.value = correctedAdviceRequest
//    }
  }
  
  public func setStation(_ state: PickerState, stationName: String) -> Promise<Void, Error> {
    return dataStore.find(stationName: stationName)
      .then {
        self.setStation(state, station: $0)
      }
      .then { _ in
        print("TravelService did set station \(stationName)")
      }
      .trap {
        print("TravelService setStation did encounter error \($0)")
      }
      .mapVoid()
  }

  public func setStation(_ state: PickerState, stationCode: String) -> Promise<Void, Error> {
    return dataStore.find(stationCode: stationCode)
      .then {
        self.setStation(state, station: $0)
      }
      .then { _ in
        print("TravelService did set station \(stationCode)")
      }
      .trap {
        print("TravelService setStation did encounter error \($0)")
      }
      .mapVoid()
  }

  public func setStation(_ state: PickerState, station: Station) {
    let advice = pickedAdviceRequest.value
    let newAdvice: AdviceRequest
    switch state {
    case .from:
      newAdvice = advice.setFrom(station)
    case .to:
      newAdvice = advice.setTo(station)
    }

    setCurrentAdviceRequest(newAdvice)
  }

  public func fetchAdvices(for adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error> {
    return apiService.advices(for: adviceRequest)
      .mapError { $0 as Error }
  }

  private func fetchCurrentAdvices(for adviceRequest: AdviceRequest? = nil, shouldEmitLoading: Bool) -> Promise<AdvicesResult, Error> {
    if shouldEmitLoading {
      currentAdvicesSource.value = .loading
    }

    return fetchAdvices(for: adviceRequest ?? pickedAdviceRequest.value)
      .then { advicesResult in
        print("TravelService fetchCurrentAdvices \(advicesResult.advices.count)")
        self.notifyOfNewAdvices(advicesResult.advices)
      }
      .trap { error in
        print(error)
      }
  }

  fileprivate func notifyOfNewAdvices(_ advices: Advices) {
    let keepDepartedAdvice = preferenceStore.keepDepartedAdvice
    let currentAdviceIdentifier = preferenceStore.currentAdviceIdentifier.value
    
    let advices = advices.filter {
      $0.isOngoing || (keepDepartedAdvice && $0.identifier == currentAdviceIdentifier)
    }

    currentAdvicesSource.value = .loaded(value: advices)

//    if let secondAdvice = advices.dropFirst().first {
//      nextAdviceVariable.value = secondAdvice
//    }
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
    let currentAdvice = pickedAdviceRequest.value
    return getCloseStations()
      .then { stations in
        guard let station = stations.first else {
          return //Promise(error: TravelServiceError.notChanged)
        }

        self.setCurrentAdviceRequest(currentAdvice.setFrom(station))
      }
      .mapVoid()
  }

  public func switchFromTo() {
    let currentAdvice = pickedAdviceRequest.value
    setCurrentAdviceRequest(AdviceRequest(from: currentAdvice.to, to: currentAdvice.from))
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  public func setCurrentAdviceOnScreen(advice: Advice?) {
    setCurrentAdviceOnScreen(adviceIdentifier: advice?.identifier)
  }

  public func setCurrentAdviceOnScreen(adviceIdentifier: AdviceIdentifier?) {
    preferenceStore.setCurrentAdviceIdentifier(identifier: adviceIdentifier)
//    preferenceStore.currentAdviceIdentifier = adviceIdentifier
//
//    queue.async {
//      let advice = self.preferenceStore.persistedAdvices?.first { $0.identifier() == adviceIdentifier }
//      self.currentAdviceOnScreenVariable.value = advice
//    }
  }

  func setMostUsedStations(stations: [Station]) {
    mostUsedStationsSource.value = stations
  }

  public func find(stationNameContains: String) -> Promise<[Station], Error> {
    return dataStore.find(stationNameContains: stationNameContains)
  }

  public func find(stationCode: String) -> Promise<Station, Error> {
    return dataStore.find(stationCode: stationCode)
  }
}

//#if os(iOS)
//
//extension TravelService: WCSessionDelegate {
//  public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//    /* stub */
//  }
//
//  public func sessionDidBecomeInactive(_ session: WCSession) {
//    /* stub */
//  }
//
//  public func sessionDidDeactivate(_ session: WCSession) {
//    /* stub */
//  }
//
//  public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
//    print(String(data: messageData, encoding: .utf8))
//  }
//
//  public func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
//    guard let advice = currentAdviceOnScreenVariable.value else {
//      return
//    }
//
//    let event = TravelEvent.currentAdviceChange(change: CurrentAdviceChangeData(identifier: advice.identifier(), fromCode: advice.request.from, toCode: advice.request.to))
//
//    guard let data = try? JSONEncoder().encode(event) else {
//      return
//    }
//
//    replyHandler(data)
//  }
//
//
//  public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
//    print("didReceiveApplicationContext: \(applicationContext)")
//  }
//}
//#endif
