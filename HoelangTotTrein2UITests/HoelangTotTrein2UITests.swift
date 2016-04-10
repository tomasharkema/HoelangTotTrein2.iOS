////
////  HoelangTotTrein2UITests.swift
////  HoelangTotTrein2UITests
////
////  Created by Tomas Harkema on 27-09-15.
////  Copyright © 2015 Tomas Harkema. All rights reserved.
////
//
//import XCTest
//
//class HoelangTotTrein2UITests: XCTestCase {
//        
//    override func setUp() {
//        super.setUp()
//        
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        
//        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
//        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        XCUIApplication().launch()
//
//        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
//    }
//    
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//    
//    func testExample() {
//      
//      let app = XCUIApplication()
//      let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(2).childrenMatchingType(.Other).elementBoundByIndex(2)
//      element.childrenMatchingType(.Button).matchingIdentifier("[Selecteer]").elementBoundByIndex(0).tap()
//      
//      let tablesQuery = app.tables
//      tablesQuery.staticTexts["'s-Hertogenbosch"].tap()
//      app.buttons["[Selecteer]"].tap()
//      tablesQuery.staticTexts["Almelo"].tap()
//      
//      let element2 = app.collectionViews.cells.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
//      element2.tap()
//      element2.tap()
//      element2.tap()
//      element.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
//
//    }
//  
//}
