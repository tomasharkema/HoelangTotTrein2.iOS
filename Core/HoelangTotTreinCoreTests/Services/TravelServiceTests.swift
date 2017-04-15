//
//  TravelServiceTests.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 15-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import XCTest
@testable import HoelangTotTreinAPI
@testable import HoelangTotTreinCore

class TravelServiceTests: XCTestCase {
  var dataStore: DataStore!
  var travelService: TravelService!
  var storageAttachment: StorageAttachment!

  override func setUp() {
    super.setUp()

    let apiService = MockApiService()
    let locationService = MockLocationService()
    dataStore = MockDataStore()
    travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore)
    storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore)

    travelService.attach()
  }

  func testSetStation() {
    let expect = expectation(description: "promise")

    dataStore.fromStationCode = "ZD"
    dataStore.toStationCode = "AMS"

    travelService.setStation(.to, stationCode: "HS")
      .then { _ in

        XCTAssertEqual(self.dataStore.fromStationCode, "ZD")
        XCTAssertEqual(self.dataStore.toStationCode, "HS")

        expect.fulfill()
      }
      .trap {
        XCTAssert(false, "Got error: \($0)")
        expect.fulfill()
      }

    waitForExpectations(timeout: 15, handler: nil)
  }

  func testSetStationFromPicker() {
    let expect = expectation(description: "promise")

    dataStore.fromStationCode = "ZD"
    dataStore.toStationCode = "AMS"
    dataStore.fromStationByPickerCode = "ZD"
    dataStore.toStationByPickerCode = "AMS"

    travelService.setStation(.to, stationCode: "HS", byPicker: true)
      .then { _ in

        XCTAssertEqual(self.dataStore.fromStationCode, "ZD")
        XCTAssertEqual(self.dataStore.toStationCode, "HS")
        XCTAssertEqual(self.dataStore.fromStationByPickerCode, "ZD")
        XCTAssertEqual(self.dataStore.toStationByPickerCode, "HS")

        expect.fulfill()
      }
      .trap {
        XCTAssert(false, "Got error: \($0)")
        expect.fulfill()
    }

    waitForExpectations(timeout: 15, handler: nil)
  }

  func testSetStationFromPickerSwitch() {
    let expect = expectation(description: "promise")

    dataStore.fromStationCode = "ZD"
    dataStore.toStationCode = "AMS"
    dataStore.fromStationByPickerCode = "ZD"
    dataStore.toStationByPickerCode = "AMS"

    travelService.setStation(.to, stationCode: "ZD", byPicker: true)
      .then { _ in
        XCTAssertEqual(self.dataStore.fromStationCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationCode, "ZD")
        XCTAssertEqual(self.dataStore.fromStationByPickerCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationByPickerCode, "ZD")

        expect.fulfill()
      }
      .trap {
        XCTAssert(false, "Got error: \($0)")
        expect.fulfill()
      }

    waitForExpectations(timeout: 15, handler: nil)
  }

  func testSetStationFromPickerDuplicate() {
    let expect = expectation(description: "promise")

    dataStore.fromStationCode = "ZD"
    dataStore.toStationCode = "AMS"
    dataStore.fromStationByPickerCode = "ZD"
    dataStore.toStationByPickerCode = "AMS"

    travelService.setStation(.to, stationCode: "ZD", byPicker: true)
      .then { _ in
        XCTAssertEqual(self.dataStore.fromStationCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationCode, "ZD")
        XCTAssertEqual(self.dataStore.fromStationByPickerCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationByPickerCode, "ZD")

        expect.fulfill()
      }
      .trap {
        XCTAssert(false, "Got error: \($0)")
        expect.fulfill()
      }

    waitForExpectations(timeout: 15, handler: nil)
  }

  func testSetStationToPickerDuplicate() {
    let expect = expectation(description: "promise")

    dataStore.fromStationCode = "ZD"
    dataStore.toStationCode = "AMS"
    dataStore.fromStationByPickerCode = "ZD"
    dataStore.toStationByPickerCode = "AMS"

    travelService.setStation(.from, stationCode: "AMS", byPicker: true)
      .then { _ in
        XCTAssertEqual(self.dataStore.fromStationCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationCode, "ZD")
        XCTAssertEqual(self.dataStore.fromStationByPickerCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationByPickerCode, "ZD")

        expect.fulfill()
      }
      .trap {
        XCTAssert(false, "Got error: \($0)")
        expect.fulfill()
      }

    waitForExpectations(timeout: 15, handler: nil)
  }

  func testSwitchFromTo() {
    let expect = expectation(description: "promise")

    dataStore.fromStationCode = "ZD"
    dataStore.toStationCode = "AMS"
    dataStore.fromStationByPickerCode = "ZD"
    dataStore.toStationByPickerCode = "AMS"

    travelService.switchFromTo()
      .then { _ in
        XCTAssertEqual(self.dataStore.fromStationCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationCode, "ZD")
        XCTAssertEqual(self.dataStore.fromStationByPickerCode, "AMS")
        XCTAssertEqual(self.dataStore.toStationByPickerCode, "ZD")

        expect.fulfill()
      }
      .trap {
        XCTAssert(false, "Got error: \($0)")
        expect.fulfill()
    }

    waitForExpectations(timeout: 15, handler: nil)
  }

  func testTravelFromCurrentLocation() {
    let expect = expectation(description: "promise")

    dataStore.fromStationCode = "AMS"
    dataStore.toStationCode = "ZD"
    dataStore.fromStationByPickerCode = "AMS"
    dataStore.toStationByPickerCode = "ZD"

    travelService.travelFromCurrentLocation()
      .then {

        XCTAssertEqual(self.dataStore.fromStationCode, "ZD")
        XCTAssertEqual(self.dataStore.toStationCode, "AMS")
        XCTAssertEqual(self.dataStore.fromStationByPickerCode, "ZD")
        XCTAssertEqual(self.dataStore.toStationByPickerCode, "AMS")

        expect.fulfill()
      }
      .trap {
        XCTAssert(false, "Got error: \($0)")
        expect.fulfill()
      }

    waitForExpectations(timeout: 15, handler: nil)
  }

}
