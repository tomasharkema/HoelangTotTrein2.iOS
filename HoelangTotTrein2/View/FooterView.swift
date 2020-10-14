//
//  FooterView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct FooterView: View {
  @EnvironmentObject var advicesAndRequest: VariableBindable<AdvicesAndRequest?>
  @Binding var expanded: Bool

  var formattedString: String? {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return (advicesAndRequest.value?.lastUpdated).flatMap {
      formatter.string(from: $0)
    }
  }

  fileprivate func CollapseToggle() -> some View {
    Button(action: {
      withAnimation {
        self.expanded.toggle()
      }
    }) {
      Image(systemName: expanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
        .padding()
    }
  }

  var body: some View {
    HStack {
      CollapseToggle()

      Spacer()
      HStack(alignment: .center, spacing: 0) {
        Text("Last updated: ")
          .foregroundColor(.white)
          .font(Font.footnote)
        Text(formattedString ?? "never")
          .foregroundColor(.white)
          .font(Font.footnote.bold())
        Button(action: {
          App.travelService.refresh()
        }) {
          Image(systemName: "arrow.2.circlepath")
            .frame(width: 20, height: 20)
        }.foregroundColor(.white).padding([.leading])
      }
    }.padding().background(Color.black.opacity(0.6))
  }
}
