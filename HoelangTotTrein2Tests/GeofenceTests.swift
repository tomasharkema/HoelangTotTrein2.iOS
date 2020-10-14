////
////  GeofenceTests.swift
////  HoelangTotTrein2
////
////  Created by Tomas Harkema on 02-03-16.
////  Copyright © 2016 Tomas Harkema. All rights reserved.
////
//
//import XCTest
//@testable

//@testable import HoelangTotTreinCore
//@testable import HLTT
//
//class GeofenceTests: XCTestCase {
//
//  var dataStore: DataStore!
//  var geofenceService: GeofenceService!
//
//  override func setUp() {
//    super.setUp()
//    dataStore = AppDataStore(useInMemoryStore: true)
//    geofenceService = GeofenceService(travelService: TravelService(apiService: MockApiService(),
//                                                                   locationService: AppLocationService(),
//                                                                   dataStore: dataStore),
//                                      dataStore: dataStore)
//  }
//  
//  // MARK: - GeofencesFromAdvices
//  
//  func testGeofencesFromAdvicesShouldGenerateRightGeofenceModelsWithNoOverstap() {
//    let advices = [
//      Advice(overstappen: 0,
//        vertrek:  FareTime(planned: 1456902049, actual: 1456902049),
//        aankomst: FareTime(planned: 1457002049, actual: 1457002049),
//        melding: nil,
//        reisDeel: [
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456902049, spoor: "1", name: "A"),
//            Stop(time: 1456912049, spoor: "1", name: "B")
//            ])
//        ],
//        vertrekVertraging: nil,
//        status: FareStatus.VolgensPlan,
//        request: AdviceRequestCodes(from: "A", to: "B")
//      )
//    ]
//    
//    let geofences = geofenceService.geofencesFromAdvices(advices)
//    
//    XCTAssertEqual(Array(geofences.keys), ["B", "A"])
//    
//    // STATION A
//    let A = geofences["A"]
//    XCTAssertNotNil(A)
//    XCTAssertEqual(A!.count, 1)
//    XCTAssertEqual(A!.first!, GeofenceModel(type: .start, stationName: "A", fromStop: Stop(time: 1456902049, spoor: "1", name: "A"), toStop: nil))
//    
//    // STATION B
//    let B = geofences["B"]
//    XCTAssertNotNil(B)
//    XCTAssertEqual(B!.count, 1)
//    XCTAssertEqual(B!.first!, GeofenceModel(type: .end, stationName: "B", fromStop: Stop(time: 1456912049, spoor: "1", name: "B"), toStop: nil))
//  }
//
//  func testGeofencesFromAdvicesShouldGenerateRightGeofenceModelsWithOneOverstap() {
//    let advices = [
//      Advice(overstappen: 0,
//        vertrek:  FareTime(planned: 1456902049, actual: 1456902049),
//        aankomst: FareTime(planned: 1457002049, actual: 1457002049),
//        melding: nil,
//        reisDeel: [
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456902049, spoor: "1", name: "A"),
//            Stop(time: 1456912049, spoor: "1", name: "B")
//          ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456922049, spoor: "1", name: "B"),
//            Stop(time: 1456932049, spoor: "1", name: "C"),
//            Stop(time: 1457002049, spoor: "1", name: "D")
//          ])
//        ],
//        vertrekVertraging: nil,
//        status: FareStatus.VolgensPlan,
//        request: AdviceRequestCodes(from: "A", to: "D")
//      )
//    ]
//    
//    let geofences = geofenceService.geofencesFromAdvices(advices)
//    
//    let keys = geofences.keys
//    XCTAssertTrue(keys.contains("A"))
//    XCTAssertTrue(keys.contains("B"))
//    XCTAssertTrue(keys.contains("C"))
//    XCTAssertTrue(keys.contains("D"))
//    
//    // STATION A
//    let A = geofences["A"]
//    XCTAssertNotNil(A)
//    XCTAssertEqual(A!.count, 1)
//    XCTAssertEqual(A!.first!, GeofenceModel(type: .start, stationName: "A", fromStop: Stop(time: 1456902049, spoor: "1", name: "A"), toStop: nil))
//    
//    // STATION B
//    let B = geofences["B"]
//    XCTAssertNotNil(B)
//    XCTAssertEqual(B!.count, 1)
//    XCTAssertEqual(B!.first!, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1456912049, spoor: "1", name: "B"), toStop: Stop(time: 1456922049, spoor: "1", name: "B")))
//    
//    // STATION C
//    let C = geofences["C"]
//    XCTAssertNotNil(C)
//    XCTAssertEqual(C!.count, 1)
//    XCTAssertEqual(C!.first!, GeofenceModel(type: .tussenStation, stationName: "C", fromStop: Stop(time: 1456932049, spoor: "1", name: "C"), toStop: nil))
//    
//    // STATION D
//    let D = geofences["D"]
//    XCTAssertNotNil(D)
//    XCTAssertEqual(D!.count, 1)
//    XCTAssertEqual(D!.first!, GeofenceModel(type: .end, stationName: "D", fromStop: Stop(time: 1457002049, spoor: "1", name: "D"), toStop: nil))
//  }
//  
//  func testGeofencesFromAdvicesShouldGenerateRightGeofenceModelsWithTwoOverstappen() {
//    let advices = [
//      Advice(overstappen: 0,
//        vertrek:  FareTime(planned: 1456902049, actual: 1456902049),
//        aankomst: FareTime(planned: 1457002049, actual: 1457002049),
//        melding: nil,
//        reisDeel: [
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456902049, spoor: "1", name: "A"),
//            Stop(time: 1456912049, spoor: "1", name: "B")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456922049, spoor: "1", name: "B"),
//            Stop(time: 1456932049, spoor: "1", name: "C"),
//            Stop(time: 1456942049, spoor: "1", name: "D")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456952049, spoor: "1", name: "D"),
//            Stop(time: 1456962049, spoor: "1", name: "E"),
//            Stop(time: 1457002049, spoor: "1", name: "F")
//            ])
//        ],
//        vertrekVertraging: nil,
//        status: FareStatus.VolgensPlan,
//        request: AdviceRequestCodes(from: "A", to: "F")
//      )
//    ]
//    
//    let geofences = geofenceService.geofencesFromAdvices(advices)
//    
//    let keys = geofences.keys
//    XCTAssertTrue(keys.contains("A"))
//    XCTAssertTrue(keys.contains("B"))
//    XCTAssertTrue(keys.contains("C"))
//    XCTAssertTrue(keys.contains("D"))
//    XCTAssertTrue(keys.contains("E"))
//    XCTAssertTrue(keys.contains("F"))
//    
//    // STATION A
//    let A = geofences["A"]
//    XCTAssertNotNil(A)
//    XCTAssertEqual(A!.count, 1)
//    XCTAssertEqual(A!.first!, GeofenceModel(type: .start, stationName: "A", fromStop: Stop(time: 1456902049, spoor: "1", name: "A"), toStop: nil))
//    
//    // STATION B
//    let B = geofences["B"]
//    XCTAssertNotNil(B)
//    XCTAssertEqual(B!.count, 1)
//    XCTAssertEqual(B!.first!, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1456912049, spoor: "1", name: "B"), toStop: Stop(time: 1456922049, spoor: "1", name: "B")))
//    
//    // STATION C
//    let C = geofences["C"]
//    XCTAssertNotNil(C)
//    XCTAssertEqual(C!.count, 1)
//    XCTAssertEqual(C!.first!, GeofenceModel(type: .tussenStation, stationName: "C", fromStop: Stop(time: 1456932049, spoor: "1", name: "C"), toStop: nil))
//    
//    // STATION D
//    let D = geofences["D"]
//    XCTAssertNotNil(D)
//    XCTAssertEqual(D!.count, 1)
//    XCTAssertEqual(D!.first!, GeofenceModel(type: .overstap, stationName: "D", fromStop: Stop(time: 1456942049, spoor: "1", name: "D"), toStop: Stop(time: 1456952049, spoor: "1", name: "D")))
//    
//    
//    // STATION E
//    let E = geofences["E"]
//    XCTAssertNotNil(E)
//    XCTAssertEqual(E!.count, 1)
//    XCTAssertEqual(E!.first!, GeofenceModel(type: .tussenStation, stationName: "E", fromStop: Stop(time: 1456962049, spoor: "1", name: "E"), toStop: nil))
//    
//    
//    // STATION F
//    let F = geofences["F"]
//    XCTAssertNotNil(F)
//    XCTAssertEqual(F!.count, 1)
//    XCTAssertEqual(F!.first!, GeofenceModel(type: .end, stationName: "F", fromStop: Stop(time: 1457002049, spoor: "1", name: "F"), toStop: nil))
//  }
//  
//  func testGeofencesFromAdvicesShouldGenerateRightGeofenceModelsWithTwoOverstappenAndMultipleAdvices() {
//    let advices = [
//      Advice(overstappen: 0,
//        vertrek:  FareTime(planned: 1456902049, actual: 1456902049),
//        aankomst: FareTime(planned: 1457002049, actual: 1457002049),
//        melding: nil,
//        reisDeel: [
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456902049, spoor: "1", name: "A"),
//            Stop(time: 1456912049, spoor: "1", name: "B")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456922049, spoor: "1", name: "B"),
//            Stop(time: 1456932049, spoor: "1", name: "C"),
//            Stop(time: 1456942049, spoor: "1", name: "D")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456952049, spoor: "1", name: "D"),
//            Stop(time: 1456962049, spoor: "1", name: "E"),
//            Stop(time: 1457002049, spoor: "1", name: "F")
//            ])
//        ],
//        vertrekVertraging: nil,
//        status: FareStatus.VolgensPlan,
//        request: AdviceRequestCodes(from: "A", to: "F")
//      ),
//      Advice(overstappen: 0,
//        vertrek:  FareTime(planned: 1457002049, actual: 1457002049),
//        aankomst: FareTime(planned: 1458002049, actual: 1458002049),
//        melding: nil,
//        reisDeel: [
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1457002049, spoor: "1", name: "A"),
//            Stop(time: 1457102049, spoor: "1", name: "B")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1457202049, spoor: "1", name: "B"),
//            Stop(time: 1457302049, spoor: "1", name: "C"),
//            Stop(time: 1457402049, spoor: "1", name: "D")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1457502049, spoor: "1", name: "D"),
//            Stop(time: 1457602049, spoor: "1", name: "E"),
//            Stop(time: 1458002049, spoor: "1", name: "F")
//            ])
//        ],
//        vertrekVertraging: nil,
//        status: FareStatus.VolgensPlan,
//        request: AdviceRequestCodes(from: "A", to: "F")
//      )
//    ]
//    
//    let geofences = geofenceService.geofencesFromAdvices(advices)
//    
//    let keys = geofences.keys
//    XCTAssertTrue(keys.contains("A"))
//    XCTAssertTrue(keys.contains("B"))
//    XCTAssertTrue(keys.contains("C"))
//    XCTAssertTrue(keys.contains("D"))
//    XCTAssertTrue(keys.contains("E"))
//    XCTAssertTrue(keys.contains("F"))
//    
//    // STATION A
//    let A = geofences["A"]
//    XCTAssertNotNil(A)
//    XCTAssertEqual(A!.count, 2)
//    XCTAssertEqual(A!.first!, GeofenceModel(type: .start, stationName: "A", fromStop: Stop(time: 1456902049, spoor: "1", name: "A"), toStop: nil))
//    
//    // STATION B
//    let B = geofences["B"]
//    XCTAssertNotNil(B)
//    XCTAssertEqual(B!.count, 2)
//    XCTAssertEqual(B!.first!, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1456912049, spoor: "1", name: "B"), toStop: Stop(time: 1456922049, spoor: "1", name: "B")))
//    
//    // STATION C
//    let C = geofences["C"]
//    XCTAssertNotNil(C)
//    XCTAssertEqual(C!.count, 2)
//    XCTAssertEqual(C!.first!, GeofenceModel(type: .tussenStation, stationName: "C", fromStop: Stop(time: 1456932049, spoor: "1", name: "C"), toStop: nil))
//    
//    // STATION D
//    let D = geofences["D"]
//    XCTAssertNotNil(D)
//    XCTAssertEqual(D!.count, 2)
//    XCTAssertEqual(D!.first!, GeofenceModel(type: .overstap, stationName: "D", fromStop: Stop(time: 1456942049, spoor: "1", name: "D"), toStop: Stop(time: 1456952049, spoor: "1", name: "D")))
//    
//    
//    // STATION E
//    let E = geofences["E"]
//    XCTAssertNotNil(E)
//    XCTAssertEqual(E!.count, 2)
//    XCTAssertEqual(E!.first!, GeofenceModel(type: .tussenStation, stationName: "E", fromStop: Stop(time: 1456962049, spoor: "1", name: "E"), toStop: nil))
//    
//    
//    // STATION F
//    let F = geofences["F"]
//    XCTAssertNotNil(F)
//    XCTAssertEqual(F!.count, 2)
//    XCTAssertEqual(F!.first!, GeofenceModel(type: .end, stationName: "F", fromStop: Stop(time: 1457002049, spoor: "1", name: "F"), toStop: nil))
//  }
//  
//  // MARK: - GeofenceFromGeofencesFromTime
//  
//  fileprivate func prepareGeofenceModels() -> GeofenceService.StationGeofences {
//    let advices = [
//      Advice(overstappen: 0,
//        vertrek:  FareTime(planned: 1456902049, actual: 1456902049),
//        aankomst: FareTime(planned: 1457002049, actual: 1457002049),
//        melding: nil, 
//        reisDeel: [
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456902049, spoor: "1", name: "A"),
//            Stop(time: 1456912049, spoor: "1", name: "B")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456922049, spoor: "1", name: "B"),
//            Stop(time: 1456932049, spoor: "1", name: "C"),
//            Stop(time: 1456942049, spoor: "1", name: "D")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1456952049, spoor: "1", name: "D"),
//            Stop(time: 1456962049, spoor: "1", name: "E"),
//            Stop(time: 1457002049, spoor: "1", name: "F")
//            ])
//        ],
//        vertrekVertraging: nil,
//        status: FareStatus.VolgensPlan,
//        request: AdviceRequestCodes(from: "A", to: "F")
//      ),
//      Advice(overstappen: 0,
//        vertrek:  FareTime(planned: 1457002049, actual: 1457002049),
//        aankomst: FareTime(planned: 1458002049, actual: 1458002049),
//        melding: nil,
//        reisDeel: [
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1457002049, spoor: "1", name: "A"),
//            Stop(time: 1457102049, spoor: "1", name: "B")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1457202049, spoor: "1", name: "B"),
//            Stop(time: 1457302049, spoor: "1", name: "C"),
//            Stop(time: 1457402049, spoor: "1", name: "D")
//            ]),
//          ReisDeel(vervoerder: "SPR", vervoerType: "SPR", stops: [
//            Stop(time: 1457502049, spoor: "1", name: "D"),
//            Stop(time: 1457602049, spoor: "1", name: "E"),
//            Stop(time: 1458002049, spoor: "1", name: "F")
//            ])
//        ],
//        vertrekVertraging: nil,
//        status: FareStatus.VolgensPlan,
//        request: AdviceRequestCodes(from: "A", to: "F")
//      )
//    ]
//    
//    return geofenceService.geofencesFromAdvices(advices)
//  }
//  
//  // MARK: Start Geofences
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnNextStartGeofenceOnTime() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["A"]!, forTime: Date(timeIntervalSince1970: 1456902049))
//    XCTAssertEqual(model, GeofenceModel(type: .start, stationName: "A", fromStop: Stop(time: 1457002049, spoor: "1", name: "A"), toStop: nil))
//  }
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnStartGeofenceBefore() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["A"]!, forTime: Date(timeIntervalSince1970: 1456901049))
//    XCTAssertEqual(model, GeofenceModel(type: .start, stationName: "A", fromStop: Stop(time: 1456902049, spoor: "1", name: "A"), toStop: nil))
//  }
//  
//  // MARK: Overstap Geofences
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnOverstappenModelBefore() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["B"]!, forTime: Date(timeIntervalSince1970: 1456901049))
//    XCTAssertEqual(model, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1456912049, spoor: "1", name: "B"), toStop: Stop(time: 1456922049, spoor: "1", name: "B")))
//  }
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnNextOverstappenModelOnTime() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["B"]!, forTime: Date(timeIntervalSince1970: 1456912049))
//    XCTAssertEqual(model, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1457102049, spoor: "1", name: "B"), toStop: Stop(time: 1457202049, spoor: "1", name: "B")))
//  }
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnOverstappenModelJustAfter() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["B"]!, forTime: Date(timeIntervalSince1970: 1456912050))
//    XCTAssertEqual(model, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1457102049, spoor: "1", name: "B"), toStop: Stop(time: 1457202049, spoor: "1", name: "B")))
//  }
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnOverstappenModelAfter() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["B"]!, forTime: Date(timeIntervalSince1970: 1456901060))
//    XCTAssertEqual(model, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1456912049, spoor: "1", name: "B"), toStop: Stop(time: 1456922049, spoor: "1", name: "B")))
//  }
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnNextOverstappenModelWhenTooLate() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["B"]!, forTime: Date(timeIntervalSince1970: 1456912050))
//    XCTAssertEqual(model, GeofenceModel(type: .overstap, stationName: "B", fromStop: Stop(time: 1457102049, spoor: "1", name: "B"), toStop: Stop(time: 1457202049, spoor: "1", name: "B")))
//  }
//
//  // MARK: Tussenstation Geofences
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnRightStationWhenTooEarly() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["C"]!, forTime: Date(timeIntervalSince1970: 1456932000))
//    XCTAssertEqual(model, GeofenceModel(type: .tussenStation, stationName: "C", fromStop: Stop(time: 1456932049, spoor: "1", name: "C"), toStop: nil))
//  }
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnRightStationWhenOnTime() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["C"]!, forTime: Date(timeIntervalSince1970: 1456932049))
//    XCTAssertEqual(model, GeofenceModel(type: .tussenStation, stationName: "C", fromStop: Stop(time: 1456932049, spoor: "1", name: "C"), toStop: nil))
//  }
//  
//  func testGeofenceFromGeofencesFromTimeShouldReturnRightStationWhenTooLate() {
//    let geofenceModels = prepareGeofenceModels()
//    
//    let model = geofenceService.geofenceFromGeofences(geofenceModels["C"]!, forTime: Date(timeIntervalSince1970: 1456932060))
//    XCTAssertEqual(model, GeofenceModel(type: .tussenStation, stationName: "C", fromStop: Stop(time: 1456932049, spoor: "1", name: "C"), toStop: nil))
//  }
//  
//}

