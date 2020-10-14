//
//  ModalityTypes.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct ModalityTypes: View {
  let legs: [Leg]

  var body: some View {
    HStack(alignment: .center) {
      ForEach(legs, id: \.hashValue) { leg in
        Text(leg.product.shortCategoryName)
      }
    }
  }
}
