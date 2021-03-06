//
//  StorageAttachment.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import API
import Bindable
import BindableNSObject
import CoreData
import Foundation
import Promissum

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

    dataStore.mostUsedStations()
      .then { [travelService] stations in
        travelService.setMostUsedStations(stations: stations)
      }
      .trap {
        print($0)
      }
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
      .trap {
        print($0)
      }

    return historyInsert.mapVoid()
  }

  func updateStations(_ stations: [Station]) -> Promise<Void, Error> {
    dataStore.findOrUpdate(stations: stations)
  }

  fileprivate func persistCurrent(_ advices: Advices, forAdviceRequest adviceRequest: AdviceRequest) {
    preferenceStore.setPersistedAdvicesAndRequest(for: adviceRequest, persisted: AdvicesAndRequest(advices: advices, adviceRequest: adviceRequest))
  }
}
