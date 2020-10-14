//
//  AdviceView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct AdviceView: View {
  let advice: Advice
  let size: CGSize?

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .center) {
        VStack {
          HStack(alignment: .center) {
            TrackView(plannedTrack: self.advice.startStation?.plannedTrack, actualTrack: self.advice.startStation?.actualTrack)
            Spacer()
            ModalityTypes(legs: self.advice.legs)
          }.padding()

          Ticker(date: self.advice.departure.actual, fontSize: 100, textAlignment: .center)
            .frame(width: self.size?.width)

          HStack {
            Spacer()
            Text(self.advice.status.rawValue)
          }.padding([.leading, .trailing], 10)
        }
      }
      Spacer()
      LegsView(legs: self.advice.legs).background(Color.black.opacity(0.2))
    }.frame(width: size?.width, height: size?.height)
  }
}
