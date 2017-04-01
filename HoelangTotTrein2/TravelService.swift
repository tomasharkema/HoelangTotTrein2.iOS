//
//  TravelService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
//import CoreDataKit
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

  init(apiService: ApiService, locationService: LocationService, dataStore: DataStore) {
    self.apiService = apiService
    self.locationService = locationService
    self.dataStore = dataStore

    super.init()

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

    firstAdviceRequest.asObservable().subscribe(onNext: { adviceRequest in
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
        self.setStation(.from, stationName: geofence.stationName)
      }).addDisposableTo(disposeBag)

    stationsObservable.asObservable().single()
      .subscribe(onNext: { _ in
        self.getCurrentAdviceRequest()
          .then { adviceRequest in

            if self.firstAdviceRequest.value != adviceRequest {
              self.firstAdviceRequest.value = adviceRequest
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

  let currentAdviceObservable = Variable<Advice?>(nil)
  let currentAdvicesObservable = Variable<Advices?>(nil)
  let stationsObservable = Variable<Stations?>(nil)
  let firstAdviceRequest = Variable<AdviceRequest?>(nil)
  let nextAdviceObservable = Variable<Advice?>(nil)
  let currentAdviceOnScreenVariable = Variable<Advice?>(nil)

  var timer: Timer?

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
    getCurrentAdviceRequest().then {
      _ = self.fetchCurrentAdvices($0)
    }
  }

  func fetchStations() -> Promise<Stations, Error> {
    return App.apiService.stations().map {
      $0.stations.filter {
        $0.land == "NL"
      }
    }.then { [weak self] stations in
      if self?.stationsObservable.value != stations {
        self?.stationsObservable.value = stations
      }
    }.trap { error in
      print(error)
    }
  }

  func getCurrentAdviceRequest() -> Promise<AdviceRequest, Error> {
    let from: Promise<Station?, Error> = UserDefaults.fromStationCode.map {
      self.dataStore.find(stationCode: $0).map { .some($0) }
    } ?? Promise(value: nil)

    let to: Promise<Station?, Error> = UserDefaults.toStationCode.map {
      self.dataStore.find(stationCode: $0).map { .some($0) }
    } ?? Promise(value: nil)

    return whenBoth(from, to)
      .map { AdviceRequest(from: $0.0, to: $0.1) }
  }

  func setCurrentAdviceRequest(_ adviceRequest: AdviceRequest, userInput: Bool) -> Promise<SuccessResult, Error> {

    let correctedAdviceRequest: Promise<AdviceRequest, Error>
    if let pickerFrom = UserDefaults.fromStationByPickerCode,
      let pickerTo = UserDefaults.toStationByPickerCode,
      !userInput && pickerTo == adviceRequest.from?.code {

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

    let registerPromise: Promise<SuccessResult, Error> = correctedAdviceRequest
      .flatMap { advice in
        guard let from = advice.from, let to = advice.to else {
          return Promise(error: TravelServiceError.notChanged)
        }
        return self.apiService.registerForNotification(UserDefaults.userId, from: from, to: to)
      }

    return registerPromise.then {
        print($0)
      }
      .trap { print($0) }
  }
  
  func setStation(_ state: PickerState, stationName: StationName, byPicker: Bool = false) -> Promise<SuccessResult, Error> {
    assert(!Thread.isMainThread)
    return dataStore.find(stationName: stationName)
      .flatMap {
        self.setStation(state, station: $0)
      }
      .trap { print($0) }
  }

  func setStation(_ state: PickerState, station: Station, byPicker: Bool = false) -> Promise<SuccessResult, Error> {
    return getCurrentAdviceRequest().flatMap { advice in
      let newAdvice: AdviceRequest
      switch state {
      case .from:
        newAdvice = advice.setFrom(station)
      case .to:
        newAdvice = advice.setTo(station)
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
    }.then { print($0) }.trap { print($0) }
  }

  func fetchCurrentAdvices(_ adviceRequest: AdviceRequest? = nil) -> Promise<AdvicesResult, Error> {
    return (adviceRequest.map { Promise(value: $0) } ?? getCurrentAdviceRequest())
      .flatMap { self.apiService.advices($0) }
      .then { advicesResult in
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
      if currentAdviceObservable.value != firstAdvice {
        currentAdviceObservable.value = firstAdvice
      }
    }
    if let secondAdvice = advices[safe: 1] {
      if nextAdviceObservable.value != secondAdvice {
        nextAdviceObservable.value = secondAdvice
      }
    }
    if currentAdvicesObservable.value != advices {
      session.sendEvent(TravelEvent.advicesChange(advice: advices))
      currentAdvicesObservable.value = advices
    }
  }

  func sortCloseLocations(_ center: CLLocation, stations: [Station]) -> [Station] {
    return stations.sorted { lhs, rhs in
      lhs.coords.location.distance(from: center) < rhs.coords.location.distance(from: center)
    }
  }

  func getCloseStations() -> Promise<[Station], Error> {
    return locationService.currentLocation().flatMap { currentLocation in
      let circularRegionBounds = CLCircularRegion(center: currentLocation.coordinate, radius: 0.1, identifier:"").bounds

      return self.dataStore.find(inBounds: circularRegionBounds)
        .flatMap { stations in
          let promiseSource = PromiseSource<[Station], Error>()

          self.queue.async {
            promiseSource.resolve(self.sortCloseLocations(currentLocation, stations: stations))
          }

          return promiseSource.promise
        }
    }
  }

  func travelFromCurrentLocation() -> Promise<SuccessResult, Error> {
    return whenBoth(getCloseStations(), getCurrentAdviceRequest()).flatMap { (stations, currentAdvice) in
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
    }.then { print($0) }.trap { print($0) }
  }

  func switchFromTo() -> Promise<SuccessResult, Error> {
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
}
