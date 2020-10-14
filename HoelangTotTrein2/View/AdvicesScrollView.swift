//
//  AdvicesScrollView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct AdvicesScrollView: View {
  @EnvironmentObject var advices: VariableBindable<AdvicesAndRequest?>
  @Binding var expanded: Bool

  private func emptyState(size: CGSize) -> some View {
    VStack(alignment: .center) {
      Spacer()
      HStack(alignment: .center) {
        Spacer()
        ActivityIndicator(isAnimating: .constant(true), style: UIActivityIndicatorView.Style.large)
        Spacer()
      }
      .frame(width: size.width, height: size.height)
      Spacer()
    }
  }

  private func listView(size: CGSize) -> some View {
    VStack(alignment: HorizontalAlignment.center) {
      ForEach(self.advices.value?.advices ?? [], id: \.hashValue) { advice in
        AdviceView(advice: advice, size: size)
          .frame(width: size.width, height: size.height)
      }
    }
  }

  private func expandedList() -> some View {
    GeometryReader { geometry in
      ScrollView {
        if (self.advices.value?.advices ?? []).isEmpty {
          self.emptyState(size: geometry.size)
        } else {
          self.listView(size: geometry.size)
        }
      }
    }
  }

  private func formattedString(_ departure: Date?) -> String? {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return departure.flatMap {
      formatter.string(from: $0)
    }
  }

  private func duration(_ duration: TimeInterval?) -> String? {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return duration.flatMap {
      formatter.string(from: $0)
    }
  }

  private func collaspedListItem(advice: Advice) -> some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 2) {
        Ticker(date: advice.departure.actual, fontSize: 20, textAlignment: .left, fontWeight: .heavy)
        HStack(spacing: 0) {
          FareTimeView(fareTime: advice.departure)
            .font(Font.footnote.weight(.light))
          Text(verbatim: "–")
            .font(Font.footnote.weight(.light))
          FareTimeView(fareTime: advice.arrival)
            .font(Font.footnote.weight(.light))
        }

        HStack {
          Text(verbatim: "\(self.duration(advice.time) ?? "")")
            .font(Font.footnote.weight(.light))
          CrowdForecastView(crowdForecast: advice.crowdForecast)
        }
      }.padding()
      CollapsedLegsView(legs: advice.legs).padding()
    }.background(Color.black.opacity(0.2))
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
      .listRowBackground(Color.clear)
  }

  private func collapsedList() -> some View {
    Group {
      if (self.advices.value?.advices ?? []).isEmpty {
        GeometryReader { geometry in
          self.emptyState(size: geometry.size)
        }
      } else {
        List(advices.value?.advices ?? [], id: \.hashValue) {
          self.collaspedListItem(advice: $0)
        }
      }
    }
  }

  var body: some View {
    VStack {
      if expanded {
        expandedList()
      } else {
        collapsedList()
      }
    }
  }
}
