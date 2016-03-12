//
//  GeofenceTests.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 02-03-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import XCTest

@testable import HLTT

class GeofenceTests: XCTestCase {

  let geofenceService = GeofenceService(travelService: TravelService(apiService: ApiService(), locationService: LocationService()))

  override func setUp() {
      super.setUp()
     
      // Put setup code here. This method is called before the invocation of each test method in the class.
      
      // In UI tests it is usually best to stop immediately when a failure occurs.
      continueAfterFailure = false
      // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
      XCUIApplication().launch()

      // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }
  
  override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()
  }

  /*
 let overstappen: Int
 let vertrek: FareTime
 let aankomst: FareTime
 let melding: Melding?
 let reisDeel: [ReisDeel]
 let vertrekVertraging: String?
 let status: FareStatus
 let request: AdviceRequestCodes
 */

  func testExample() {
    let advices = [
      Advice(overstappen: 0,
        vertrek:  FareTime(planned: 1456902049, actual: 1456902049),
        aankomst: FareTime(planned: 1457002049, actual: 1457002049),
        melding: nil,
        reisDeel: [],
        vertrekVertraging: nil,
        status: FareStatus.VolgensPlan,
        request: AdviceRequestCodes(from: "A", to: "B")
      )
    ]


      // Use recording to get started writing UI tests.
      // Use XCTAssert and related functions to verify your tests produce the correct results.
  }

}
