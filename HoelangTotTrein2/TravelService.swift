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
import RxSwift
import WatchConnectivity

class TravelService: NSObject, WCSessionDelegate {
  let queue = DispatchQueue(label: "nl.tomasharkema.TravelService", attributes: [])
  fileprivate let apiService: ApiService
  fileprivate let locationService: LocationService

  fileprivate var disposeBag = DisposeBag()

  let session = WCSession.default()

  init(apiService: ApiService, locationService: LocationService) {
    self.apiService = apiService
    self.locationService = locationService

    super.init()

    NotificationCenter.defaultCenter().addObserver(self, selector: #selector(startTimer), name: UIApplicationDidBecomeActiveNotification, object: nil)
    NotificationCenter.defaultCenter().addObserver(self, selector: #selector(stopTimer), name: UIApplicationDidEnterBackgroundNotification, object: nil)
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

    firstAdviceRequest.asObservable().subscribeNext { [weak self] adviceRequest in
      guard let adviceRequest = adviceRequest, service = self else {
        return
      }
      if let from = adviceRequest.from {
        UserDefaults.fromStationCode = from.code
      }

      if let to = adviceRequest.to {
        UserDefaults.toStationCode = to.code
      }

      self?.fetchCurrentAdvices(adviceRequest)
    }.addDisposableTo(disposeBag)

    App.geofenceService.geofenceObservable.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .filter { $0.type != .TussenStation }
      .subscribeNext { [weak self] geofence in
        self?.setStation(.From, stationName: geofence.stationName)
      }.addDisposableTo(disposeBag)

    stationsObservable.asObservable().single().subscribeNext { [weak self] _ in
      if let service = self {
        let adviceRequest = service.getCurrentAdviceRequest()
        if service.firstAdviceRequest.value != adviceRequest {
          service.firstAdviceRequest.value = adviceRequest
        }
        if let advicesAndRequest = UserDefaults.persistedAdvicesAndRequest where advicesAndRequest.adviceRequest == adviceRequest {
          self?.notifyOfNewAdvices(advicesAndRequest.advices)
        }
      }
    }.addDisposableTo(disposeBag)

    currentAdviceOnScreenVariable.asObservable().filterOptional().debounce(3, scheduler: MainScheduler.asyncInstance).subscribeNext { [weak self] advice in
      guard let service = self else {
        return
      }

      service.session.sendEvent(TravelEvent.CurrentAdviceChange(hash: advice.hashValue))
      let complicationUpdate = service.session.transferCurrentComplicationUserInfo(["delay": advice.vertrekVertraging ?? "+ 1 min"])
      print(complicationUpdate)
    }.addDisposableTo(disposeBag)

    currentAdvicesObservable.asObservable().filterOptional().subscribeNext { [weak self] advices in
      guard let service = self else {
        return
      }

      let element = advices.enumerate().filter { $0.element.hashValue == UserDefaults.currentAdviceHash }.first?.element ?? advices.first

      service.currentAdviceOnScreenVariable.value = element
    }.addDisposableTo(disposeBag)
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
    fetchCurrentAdvices(getCurrentAdviceRequest())
  }

  func fetchStations() -> Promise<Stations, ErrorType> {
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

  func getCurrentAdviceRequest(_ context: NSManagedObjectContext = CDK.mainThreadContext) -> AdviceRequest {
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

  func setCurrentAdviceRequest(_ adviceRequest: AdviceRequest, userInput: Bool) {
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
    if firstAdviceRequest.value != correctedAdviceRequest {
      firstAdviceRequest.value = correctedAdviceRequest
    }
  }
  
  func setStation(_ state: PickerState, stationName: StationName, byPicker: Bool = false) {
    assert(Thread.isMainThread)
    let predicate = NSPredicate(format: "name = %@", stationName)
    do {
      if let station = try CDK.mainThreadContext.findFirst(StationRecord.self, predicate: predicate, sortDescriptors: nil, offset: nil)?.toStation() {
        setStation(state, station: station, byPicker: byPicker)
      }
    } catch {
      print(error)
    }
  }

  func setStation(_ state: PickerState, station: Station, byPicker: Bool = false) {
    let advice = getCurrentAdviceRequest()
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

    setCurrentAdviceRequest(newAdvice, userInput: byPicker)
  }

  func fetchCurrentAdvices(_ adviceRequest: AdviceRequest? = nil) -> Promise<AdvicesResult, ErrorType> {
    return apiService.advices(adviceRequest ?? getCurrentAdviceRequest()).then { [weak self] advicesResult in
      self?.notifyOfNewAdvices(advicesResult.advices)
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

  func stationByCode(_ code: String, context: NSManagedObjectContext = CDK.mainThreadContext) -> Station? {
    guard let stationRecord = try? context.findFirst(StationRecord.self, predicate: NSPredicate(format: "code = %@", code)) else {
      return nil
    }

    return stationRecord?.toStation()
  }

  func sortCloseLocations(_ center: CLLocation, stations: [StationRecord]) -> [StationRecord] {
    return stations.sorted { lhs, rhs in
      lhs.toStation().coords.location.distance(from: center) < rhs.toStation().coords.location.distance(from: center)
    }
  }

  func getCloseStations() -> Promise<[StationRecord], ErrorType> {
    return locationService.currentLocation().flatMap { [weak self] currentLocation in

      guard let service = self else {
        return Promise(error: NSError(domain: "HLTT", code: 500, userInfo: nil))
      }

      let circularRegionBounds = CLCircularRegion(center: currentLocation.coordinate, radius: 0.1, identifier:"").bounds

      let predicate = NSPredicate(format: "lat > %f AND lat < %f AND lon > %f AND lon < %f", circularRegionBounds.latmin, circularRegionBounds.latmax, circularRegionBounds.lonmin, circularRegionBounds.lonmax)
      if let stations = try? CDK.mainThreadContext.find(StationRecord.self, predicate: predicate, sortDescriptors: nil, limit: nil) {
        return Promise(value: service.sortCloseLocations(currentLocation, stations: stations))
      }

      return Promise(error: NSError(domain: "HLTT", code: 500, userInfo: nil))
    }
  }

  func travelFromCurrentLocation() {
    queue.async { [weak self] in
      if let service = self {
        service.getCloseStations().map { (stationRecords: [StationRecord]) in
          stationRecords.map { (stationRecord: StationRecord) in
            stationRecord.toStation()
          }
        }.then {
          if let station = $0.first {
            let currentAdvice = service.getCurrentAdviceRequest(CDK.backgroundContext)

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
    let currentAdvice = getCurrentAdviceRequest()
    setCurrentAdviceRequest(AdviceRequest(from: currentAdvice.to, to: currentAdvice.from), userInput: true)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
    guard let advice = currentAdviceOnScreenVariable.value?.encodeJson(), data = jsonToNSData(advice) else {
      return
    }

    replyHandler(data)
  }
}
