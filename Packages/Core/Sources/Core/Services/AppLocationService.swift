//
//  LocationService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 03-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import API
import Bindable
import CoreLocation
import Foundation
import Promissum

struct SignificantLocation: Equatable {
  let location: CLLocation
  let neighbouringStations: [Station]
}

public class AppLocationService: NSObject, CLLocationManagerDelegate, LocationService {
  let manager: CLLocationManager

  let significantLocationChange: Variable<SignificantLocation?>
  private let significantLocationChangeSource = VariableSource<SignificantLocation?>(value: nil)

  override public init() {
    manager = CLLocationManager()
    significantLocationChange = significantLocationChangeSource.variable
    super.init()
    manager.delegate = self
  }

  deinit {
    requestAuthorizationPromise = nil
    currentLocationPromise = nil
  }

  public func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    requestAuthorizationPromise?.resolve(status)
  }

  fileprivate var requestAuthorizationPromise: PromiseSource<CLAuthorizationStatus, Error>?

  public func requestAuthorization() -> Promise<CLAuthorizationStatus, Error> {
    let currentState = CLLocationManager.authorizationStatus()

    switch currentState {
    case .authorizedAlways, .authorizedWhenInUse:
      return Promise(value: currentState)

    default:
      requestAuthorizationPromise = PromiseSource<CLAuthorizationStatus, Error>()
      manager.requestAlwaysAuthorization()
      return requestAuthorizationPromise?.promise ?? Promise(error: NSError(domain: "HLTT", code: 500, userInfo: nil))
    }
  }

  fileprivate var currentLocationPromise: PromiseSource<CLLocation, Error>?

  public func currentLocation() -> Promise<CLLocation, Error> {
    if let location = manager.location, DateInterval(start: location.timestamp, end: Date()).duration < 560 {
      return Promise(value: location)
    }

    return requestAuthorization().flatMap { _ in
      if self.currentLocationPromise?.promise.result != nil || self.currentLocationPromise == nil {
        self.currentLocationPromise = PromiseSource<CLLocation, Error>()
      }
      self.manager.requestLocation()
      return self.currentLocationPromise!.promise
    }
  }

  public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
  public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
    currentLocationPromise?.reject(error)
  }
}
