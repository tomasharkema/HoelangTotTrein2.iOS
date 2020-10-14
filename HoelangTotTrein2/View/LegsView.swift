//
//  LegsView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct LegsView: View {
  let legs: [Leg]

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(legs, id: \.name) { leg in
        VStack {
          HStack {
            Spacer()
            CrowdForecastView(crowdForecast: leg.crowdForecast)
            Text("\(leg.product.shortCategoryName) ri. \(leg.direction ?? "")")
              .font(Font.subheadline)
          }.padding(.bottom, 4)
          LegView(leg: leg)
        }.padding()
      }
    }
  }
}
