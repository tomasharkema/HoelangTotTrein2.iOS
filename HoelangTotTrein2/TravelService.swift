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

  private let apiService: ApiService

  private var currentAdviceRequestSubscription: ObservableSubject<AdviceRequest>!

  init(apiService: ApiService) {
    self.apiService = apiService
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

  func getCurrentAdvice() -> AdviceRequest {
    do {
      let from: Station?
      if let fromCode = UserDefaults.fromStationCode {
        let fromPredicate = NSPredicate(format: "code = %@", fromCode)
        from = try CDK.mainThreadContext.findFirst(StationRecord.self, predicate: fromPredicate)?.toStation()
      } else {
        from = nil
      }
      let to: Station?
      if let toCode = UserDefaults.toStationCode {
        let toPredicate = NSPredicate(format: "code = %@", toCode)
        to = try CDK.mainThreadContext.findFirst(StationRecord.self, predicate: toPredicate)?.toStation()
      } else {
        to = nil
      }

      return AdviceRequest(from: from, to: to)
    } catch {
      return AdviceRequest(from: nil, to: nil)
    }
  }

  func setCurrentAdviceRequest(adviceRequest: AdviceRequest) {
    currentAdviceRequest.next(adviceRequest)
  }

  func setStation(state: PickerState, station: Station) {
    let advice = getCurrentAdvice()
    let newAdvice: AdviceRequest
    switch state {
    case .From:
      newAdvice = advice.setFrom(station)
    case .To:
      newAdvice = advice.setTo(station)
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

}