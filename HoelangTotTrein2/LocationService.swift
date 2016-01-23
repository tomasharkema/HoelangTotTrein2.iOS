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

struct SignificantLocation: Equatable {
  let location: CLLocation
  let neighbouringStations: [Station]
}

func ==(lhs: SignificantLocation, rhs: SignificantLocation) -> Bool {
  return lhs.location.isEqual(rhs.location)
}

class LocationService: NSObject, CLLocationManagerDelegate {

  let manager: CLLocationManager

  let significantLocationChangeObservable = Observable<SignificantLocation>()

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

  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    requestAuthorizationPromise?.resolve(status)
    switch status {
    case .AuthorizedAlways:
      initialize()
    default:
      break
    }
  }

  private var requestAuthorizationPromise: PromiseSource<CLAuthorizationStatus, ErrorType>?

  func requestAuthorization() -> Promise<CLAuthorizationStatus, ErrorType> {
    let currentState = CLLocationManager.authorizationStatus()

    switch currentState {
    case .AuthorizedAlways:
      return Promise(value: currentState)

    default:
      requestAuthorizationPromise = PromiseSource<CLAuthorizationStatus, ErrorType>()
      manager.requestAlwaysAuthorization()
      return requestAuthorizationPromise?.promise ?? Promise(error: NSError(domain: "HLTT", code: 500, userInfo: nil))
    }
  }

  private var currentLocationPromise: PromiseSource<CLLocation, ErrorType>?

  func currentLocation() -> Promise<CLLocation, ErrorType> {
    currentLocationPromise = PromiseSource<CLLocation, ErrorType>()
    manager.requestLocation()
    return currentLocationPromise!.promise
  }

  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let closestLocation = locations.sort { lhs, rhs in
      (lhs.horizontalAccuracy + lhs.verticalAccuracy) > (rhs.horizontalAccuracy + rhs.verticalAccuracy)
    }.first

    if let closestLocation = closestLocation {
      currentLocationPromise?.resolve(closestLocation)
    } else {
      currentLocationPromise?.reject(NSError(domain: "HLTT", code: 500, userInfo: nil))
    }
  }
}

extension LocationService {
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    currentLocationPromise?.reject(error)
  }
}