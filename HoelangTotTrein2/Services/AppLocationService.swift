//
//  LocationService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 03-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreLocation
import Promissum
import RxSwift
#if os(watchOS)
  import HoelangTotTreinAPIWatch
  import HoelangTotTreinCoreWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
  import HoelangTotTreinCore
#endif

struct SignificantLocation: Equatable {
  let location: CLLocation
  let neighbouringStations: [Station]
}

func ==(lhs: SignificantLocation, rhs: SignificantLocation) -> Bool {
  return lhs.location == rhs.location
}

class AppLocationService: NSObject, CLLocationManagerDelegate, LocationService {

  let manager: CLLocationManager

  let significantLocationChangeObservable = Variable<SignificantLocation?>(nil).asObservable()

  override init() {
    manager = CLLocationManager()
    super.init()
    manager.delegate = self

    initialize()
  }

  func initialize() {

  }

  deinit {
    requestAuthorizationPromise = nil
    currentLocationPromise = nil
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    requestAuthorizationPromise?.resolve(status)
    switch status {
    case .authorizedAlways:
      initialize()
    default:
      break
    }
  }

  fileprivate var requestAuthorizationPromise: PromiseSource<CLAuthorizationStatus, Error>?

  func requestAuthorization() -> Promise<CLAuthorizationStatus, Error> {
    let currentState = CLLocationManager.authorizationStatus()

    switch currentState {
    case .authorizedAlways:
      return Promise(value: currentState)

    default:
      requestAuthorizationPromise = PromiseSource<CLAuthorizationStatus, Error>()
      manager.requestAlwaysAuthorization()
      return requestAuthorizationPromise?.promise ?? Promise(error: NSError(domain: "HLTT", code: 500, userInfo: nil))
    }
  }

  fileprivate var currentLocationPromise: PromiseSource<CLLocation, Error>?

  func currentLocation() -> Promise<CLLocation, Error> {
    if let location = manager.location, DateInterval(start: location.timestamp, end: Date()).duration < 560 {
      return Promise(value: location)
    }

    if currentLocationPromise?.promise.result != nil || currentLocationPromise == nil {
      currentLocationPromise = PromiseSource<CLLocation, Error>()
    }
    manager.requestLocation()
    return currentLocationPromise!.promise
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let closestLocation = locations.sorted { lhs, rhs in
      (lhs.horizontalAccuracy + lhs.verticalAccuracy) > (rhs.horizontalAccuracy + rhs.verticalAccuracy)
    }.first

    if let closestLocation = closestLocation {
      currentLocationPromise?.resolve(closestLocation)
    } else {
      currentLocationPromise?.reject(NSError(domain: "HLTT", code: 500, userInfo: nil))
    }
  }
}

extension AppLocationService {
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    currentLocationPromise?.reject(error)
  }
}
