//
//  StorageAttachment.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import Bindable
import Promissum
#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

public class StorageAttachment: NSObject {

  private let travelService: TravelService
  private let dataStore: DataStore
  private let preferenceStore: PreferenceStore

  public init(travelService: TravelService, dataStore: DataStore, preferenceStore: PreferenceStore) {
    self.travelService = travelService
    self.dataStore = dataStore
    self.preferenceStore = preferenceStore

    super.init()

    start()
  }

  private func start() {
    travelService.stations.subscribe { [weak self] event in
      self?.updateStations(event.value)
    }.disposed(by: disposeBag)

    travelService.originalAdviceRequest.subscribe { [weak self] event in
      self?.insertHistoryFromRequest(event.value)
    }.disposed(by: disposeBag)
  }

//  public func attach() {
//
//    _ = travelService.currentAdvicesObservable
//      .asObservable()
//      .observeOn(scheduler)
//      .map { $0.value }
//      .filterOptional()
//      .subscribe(onNext: { [preferenceStore, travelService] advices in
//        preferenceStore.persistedAdvices = advices
//        self.persistCurrent(advices, forAdviceRequest: travelService.pickedAdviceRequest.value)
//      })
//
//    // prepopulate stations history
//
//    dataStore.mostUsedStations()
//      .then { [travelService] stations in
//        travelService.setMostUsedStations(stations: stations)
//      }
//  }

  func insertHistoryFromRequest(_ advice: AdviceRequest) -> Promise<Void, Error> {

    guard let from = advice.from, let to = advice.to else {
      return Promise(error: NSError(domain: "", code: 0, userInfo: nil))
    }

    let historyInsert = whenBoth(
      dataStore.insertHistory(stationCode: from, historyType: .from),
      dataStore.insertHistory(stationCode: to, historyType: .to)
    )

    historyInsert
      .flatMap { _ in self.dataStore.mostUsedStations() }
      .then { [travelService] stations in
        travelService.setMostUsedStations(stations: stations)
      }

    return historyInsert.mapVoid()
  }

  func updateStations(_ stations: [Station]) -> Promise<Void, Error> {
    return dataStore.findOrUpdate(stations: stations)
  }

  fileprivate func persistCurrent(_ advices: Advices, forAdviceRequest adviceRequest: AdviceRequest) {
    preferenceStore.persistedAdvicesAndRequest = AdvicesAndRequest(advices: advices, adviceRequest: adviceRequest)
  }
}
