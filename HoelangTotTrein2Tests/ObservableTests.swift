//
//  ObservableTests.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 15-03-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import XCTest

@testable import HLTT

class ObservableTests: XCTestCase {
  //  override func setUp() {
//      super.setUp()
//      // Put setup code here. This method is called before the invocation of each test method in the class.
  //  }
//
  //  override func tearDown() {
//      // Put teardown code here. This method is called after the invocation of each test method in the class.
//      super.tearDown()
  //  }

  func testSubscribeObservableShouldReturnSubject() {
    let observable = Observable<String>()

    let observableSubject = observable.subscribe {
      print($0)
    }

    XCTAssertNotNil(observableSubject)
  }

  func testSubscribeShouldRegisterCallbackAndInvokeCallbackOnNext() {
    let observable = Observable<String>()

    let expectation = expectationWithDescription("")

    observable.subscribe {
      print($0)
      expectation.fulfill()
    }

    observable.next("Hallo!")

    waitForExpectationsWithTimeout(10) {
      print("Error: \($0)")
    }
  }

  func testSubscribeShouldRegisterCallbackAndInvokeCallbackOnNextTwice() {
    let observable = Observable<String>()

    let expectation = expectationWithDescription("")

    var numberCalled = 0

    observable.subscribe {
      print($0)
      numberCalled += 1
    }

    dispatch_async(dispatch_get_main_queue()) {
      observable.next("Hallo!")

      dispatch_async(dispatch_get_main_queue()) {
        observable.next("Hallo!!")

        dispatch_async(dispatch_get_main_queue()) {
          print(numberCalled)

          if numberCalled == 2 {
            expectation.fulfill()
          }
        }
      }
    }

    waitForExpectationsWithTimeout(10) {
      print(numberCalled)
      print("Error: \($0)")
    }
  }

  func testSubscribeShouldRegisterCallbackAndInvokeCallbackOnNextOnceWhenSameValue() {
    let observable = Observable<String>()

    let expectation = expectationWithDescription("")

    var numberCalled = 0

    observable.subscribe {
      print($0)
      numberCalled += 1
    }

    dispatch_async(dispatch_get_main_queue()) {
      observable.next("Hallo!")

      dispatch_async(dispatch_get_main_queue()) {
        observable.next("Hallo!")

        dispatch_async(dispatch_get_main_queue()) {
          if numberCalled == 1 {
            expectation.fulfill()
          }
        }
      }
    }

    waitForExpectationsWithTimeout(10) {
      print(numberCalled)
      print("Error: \($0)")
    }
  }
}
