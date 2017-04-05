//
//  TravelService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import Promissum
import RxSwift
import WatchConnectivity

enum TravelServiceError: Error {
  case notChanged
}

class TravelService: NSObject, WCSessionDelegate {
  let queue = DispatchQueue(label: "nl.tomasharkema.TravelService", attributes: [])
  fileprivate let apiService: ApiService
  fileprivate let locationService: LocationService
  private let dataStore: DataStore

  fileprivate var disposeBag = DisposeBag()

  let session = WCSession.default()

  private let currentAdviceVariable = Variable<Advice?>(nil)
  private(set) var currentAdviceObservable: Observable<Advice?>!
  private let currentAdvicesVariable = Variable<Advices?>(nil)
  private(set) var currentAdvicesObservable: Observable<Advices?>!
  private let stationsVariable = Variable<Stations?>(nil)
  private(set) var stationsObservable: Observable<Stations?>!
  private let firstAdviceRequestVariable = Variable<AdviceRequest?>(nil)
  private(set) var firstAdviceRequestObservable: Observable<AdviceRequest?>!
  private let nextAdviceVariable = Variable<Advice?>(nil)
  private(set) var nextAdviceObservable: Observable<Advice?>!
  private let currentAdviceOnScreenVariable = Variable<Advice?>(nil)
  private(set) var currentAdviceOnScreenObservable: Observable<Advice?>!
  private let mostUsedStationsVariable = Variable<[Station]>([])
  private(set) var mostUsedStationsObservable: Observable<[Station]>!

  var timer: Timer?

  init(apiService: ApiService, locationService: LocationService, dataStore: DataStore) {
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
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    /* stub */
  }
  
  func sessionDidBecomeInactive(_ session: WCSession) {
    /* stub */
  }
  
  open func sessionDidDeactivate(_ session: WCSession) {
    /* stub */
  }
  
  func attach() {

    session.delegate = self
    session.activate()

    firstAdviceRequestObservable.subscribe(onNext: { adviceRequest in
      guard let adviceRequest = adviceRequest else {
        return
      }

      if let from = adviceRequest.from {
        UserDefaults.fromStationCode = from.code
      }

      if let to = adviceRequest.to {
        UserDefaults.toStationCode = to.code
      }

      _ = self.fetchCurrentAdvices(adviceRequest)
    }).addDisposableTo(disposeBag)

    App.geofenceService.geofenceObservable?.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .filter { $0.type != .TussenStation }
      .subscribe(onNext: { geofence in
        _ = self.setStation(.from, stationName: geofence.stationName)
      }).addDisposableTo(disposeBag)

    stationsObservable.asObservable()
      .single()
      .subscribe(onNext: { _ in
        self.getCurrentAdviceRequest()
          .dispatch(on: self.queue)
          .then { adviceRequest in
            if self.firstAdviceRequestVariable.value != adviceRequest {
              self.firstAdviceRequestVariable.value = adviceRequest
            }

            if let advicesAndRequest = UserDefaults.persistedAdvicesAndRequest, advicesAndRequest.adviceRequest == adviceRequest {
              self.notifyOfNewAdvices(advicesAndRequest.advices)
            }
          }
      }).addDisposableTo(disposeBag)

    currentAdviceOnScreenVariable.asObservable().filterOptional().debounce(3, scheduler: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] advice in
      guard let service = self else {
        return
      }

      service.session.sendEvent(TravelEvent.currentAdviceChange(hash: advice.hashValue))
      let complicationUpdate = service.session.transferCurrentComplicationUserInfo(["delay": advice.vertrekVertraging ?? "+ 1 min"])
      print(complicationUpdate)
    }).addDisposableTo(disposeBag)

    currentAdvicesObservable.asObservable().filterOptional().subscribe(onNext: { [weak self] advices in
      guard let service = self else {
        return
      }

      let element = advices.enumerated().filter { $0.element.hashValue == UserDefaults.currentAdviceHash }.first?.element ?? advices.first

      service.currentAdviceOnScreenVariable.value = element
    }).addDisposableTo(disposeBag)
  }

  func startTimer() {
    if timer == nil {
      timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    tick()
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  func tick() {
    getCurrentAdviceRequest()
      .dispatch(on: queue)
      .then {
        _ = self.fetchCurrentAdvices($0)
      }
  }

  func fetchStations() -> Promise<Stations, Error> {
    return App.apiService.stations()
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
    let from: Promise<Station?, Error> = UserDefaults.fromStationCode.map {
      self.dataStore.find(stationCode: $0)
        .dispatch(on: queue)
        .map {
          .some($0)
        }
    } ?? Promise(value: nil)

    let to: Promise<Station?, Error> = UserDefaults.toStationCode.map {
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
    if let pickerFrom = UserDefaults.fromStationByPickerCode,
      let pickerTo = UserDefaults.toStationByPickerCode,
      /*!userInput &&*/ pickerTo == adviceRequest.from?.code {

      correctedAdviceRequest = whenBoth(dataStore.find(stationCode: pickerFrom), dataStore.find(stationCode: pickerTo))
        .then {
          UserDefaults.fromStationByPickerCode = $0.1.code
          UserDefaults.toStationByPickerCode = $0.0.code
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
        return self.apiService.registerForNotification(UserDefaults.userId, from: from, to: to)
      }

    return registerPromise.mapVoid()
  }
  
  func setStation(_ state: PickerState, stationName: StationName, byPicker: Bool = false) -> Promise<Void, Error> {
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

  func setStation(_ state: PickerState, station: Station, byPicker: Bool = false) -> Promise<Void, Error> {
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
            UserDefaults.fromStationByPickerCode = station.code
          case .to:
            UserDefaults.toStationByPickerCode = station.code
          }
        }

        return self.setCurrentAdviceRequest(newAdvice, userInput: byPicker)
      }
  }

  func fetchCurrentAdvices(_ adviceRequest: AdviceRequest? = nil) -> Promise<AdvicesResult, Error> {
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
      return $0.isOngoing
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
    if currentAdvicesVariable.value != advices {
      session.sendEvent(TravelEvent.advicesChange(advice: advices))
      currentAdvicesVariable.value = advices
    }
  }

  func sortCloseLocations(_ center: CLLocation, stations: [Station]) -> [Station] {
    return stations.sorted { lhs, rhs in
      lhs.coords.location.distance(from: center) < rhs.coords.location.distance(from: center)
    }
  }

  func getCloseStations() -> Promise<[Station], Error> {
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

  func travelFromCurrentLocation() -> Promise<Void, Error> {
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

  func switchFromTo() -> Promise<Void, Error> {
    return getCurrentAdviceRequest().flatMap { currentAdvice in
      self.setCurrentAdviceRequest(AdviceRequest(from: currentAdvice.to, to: currentAdvice.from), userInput: true)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
    guard let advice = currentAdviceOnScreenVariable.value?.encodeJson(), let data = jsonToNSData(advice) else {
      return
    }

    replyHandler(data)
  }

  func setCurrentAdviceOnScreen(advice: Advice?) {
    currentAdviceOnScreenVariable.value = advice
  }

  func setMostUsedStations(stations: [Station]) {
    mostUsedStationsVariable.value = stations
  }

  func find(stationNameContains: String) -> Promise<[Station], Error> {
    return dataStore.find(stationNameContains: stationNameContains)
  }
}
