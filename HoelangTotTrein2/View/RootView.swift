//
//  RootView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 17/07/2019.
//  Copyright © 2019 Tomas Harkema. All rights reserved.
//

import API
import Bindable
import Core
import SwiftUI

struct RootView: View {
  @State var expanded: Bool = false

  var body: some View {
    HStack {
      VStack(alignment: HorizontalAlignment.center, spacing: 0) {
        HeaderPickerView()
        AdvicesScrollView(expanded: $expanded)
        FooterView(expanded: $expanded)
      }
    }.background(Image("bg")).foregroundColor(Color.white)
  }
}
