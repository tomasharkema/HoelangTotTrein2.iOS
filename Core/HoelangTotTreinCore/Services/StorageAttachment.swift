//
//  StorageAttachment.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import RxSwift
import Promissum
#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

public class StorageAttachment {
  private let queue = DispatchQueue(label: "nl.tomasharkema.StorageAttachment", attributes: [])
//  let scheduler = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: "nl.tomasharkema.StorageAttachment")
  private let travelService: TravelService
  private var disposeBag = DisposeBag()

  private let dataStore: DataStore


  public init(travelService: TravelService, dataStore: DataStore) {
    self.travelService = travelService
    self.dataStore = dataStore
  }

  func updateStations(_ stations: [Station]) -> Promise<Void, Error> {
    return dataStore.findOrUpdate(stations: stations)
  }

  public func attach() {

    travelService.stationsObservable.asObservable()
//      .observeOn(scheduler)
      .subscribe { [weak self] in
        switch $0 {
        case let .next(stations?):
          self?.updateStations(stations)
            .then {
              print($0)
            }
            .trap {
              print($0)
            }
        default: break;
        }
      }.addDisposableTo(disposeBag)

    travelService.firstAdviceRequestObservable
//      .observeOn(scheduler)
      .filterOptional()
      .subscribe(onNext: { [weak self] in
        self?.insertHistoryFromRequest($0)
      })
      .addDisposableTo(disposeBag)

    travelService.currentAdvicesObservable
      .asObservable()
//      .observeOn(MainScheduler.asyncInstance)
      .map { $0.value }
      .filterOptional()
      .subscribe(onNext: { advices in
        self.travelService.getCurrentAdviceRequest()
          .dispatch(on: self.queue)
          .then { advice in
            self.persistCurrent(advices, forAdviceRequest: advice)
          }
          .trap { print($0) }
      })
      .addDisposableTo(disposeBag)

    // prepopulate stations history

    dataStore.mostUsedStations()
      .then { stations in
        self.travelService.setMostUsedStations(stations: stations)
      }
  }

  func insertHistoryFromRequest(_ advice: AdviceRequest) -> Promise<Void, Error> {

    guard let from = advice.from, let to = advice.to else {
      return Promise(error: NSError(domain: "", code: 0, userInfo: nil))
    }

    let historyInsert = whenBoth(
      dataStore.insertHistory(station: from, historyType: .from),
      dataStore.insertHistory(station: to, historyType: .to)
    )

    historyInsert
      .flatMap { _ in self.dataStore.mostUsedStations() }
      .then { stations in
        self.travelService.setMostUsedStations(stations: stations)
      }

    return historyInsert.mapVoid()
  }

  fileprivate func persistCurrent(_ advices: Advices, forAdviceRequest adviceRequest: AdviceRequest) {
    dataStore.persistedAdvicesAndRequest = AdvicesAndRequest(advices: advices, adviceRequest: adviceRequest)
  }
}
