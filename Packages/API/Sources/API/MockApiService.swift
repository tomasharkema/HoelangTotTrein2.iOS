//
//  MockApiService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 15-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import CancellationToken
import Foundation
import Promissum

class MockApiService: ApiService {
  private let date = Date().timeIntervalSince1970

  func stations(cancellationToken _: CancellationToken?) -> Promise<StationsResponse, ApiError> {
    Promise(value: StationsResponse(payload: [])) // TODO: fix deze eens!
  }

  private func generateAdvices(n _: Int, from _: String, to _: String, startTime _: Double = 1000, duration _: Double = 1000) -> Advices {
    fatalError()
//    return (0..<n).map { (i) -> Advice in
//
//      let start = startTime + self.date + (duration * Double(i))
//      let end = startTime + duration + self.date + (duration * Double(i))
//      let middle = end - (duration / 2)
//      return Advice(overstappen: 1,
//                    vertrek: FareTime(planned: Date(timeIntervalSince1970: start), actual: Date(timeIntervalSince1970: start)),
//             aankomst: FareTime(planned: Date(timeIntervalSince1970: end), actual: Date(timeIntervalSince1970: end)),
//             melding: nil,
//             reisDeel: [
//              ReisDeel(vervoerder: "SPR", vervoerType: "SPR", ritNummer: "AAA", stops: [
//                Stop(time: Date(timeIntervalSince1970: start), spoor: "1", name: from),
//                Stop(time: Date(timeIntervalSince1970: middle), spoor: "1", name: "ASS")
//                ]),
//              ReisDeel(vervoerder: "IC", vervoerType: "SPR", ritNummer: "BBB", stops: [
//                Stop(time: Date(timeIntervalSince1970: middle + 1), spoor: "1", name: "ASS"),
//                Stop(time: Date(timeIntervalSince1970: end), spoor: "1", name: to)
//                ])
//        ],
//             vertrekVertraging: nil,
//             status: FareStatus.volgensPlan,
//             request: AdviceRequestCodes(from: from, to: to)
//      )
//    }
  }

  func advices(for adviceRequest: AdviceRequest, scrollRequestForwardContext _: String?, cancellationToken _: CancellationToken?) -> Promise<AdvicesResponse, ApiError> {
    guard let from = adviceRequest.from, let to = adviceRequest.to else {
      return Promise(error: ApiError.noFullRequest)
    }
    fatalError()
//    return Promise(value: AdvicesResponse(advices: generateAdvices(n: 10, from: from.code, to: to.code)))
  }

  func registerForNotification(_: String, from _: Station, to _: Station) -> Promise<SuccessResult, ApiError> {
    Promise(value: SuccessResult(success: true))
  }

  func registerForNotification(_: String, env _: String, pushUUID _: String) -> Promise<SuccessResult, ApiError> {
    Promise(value: SuccessResult(success: true))
  }
}
