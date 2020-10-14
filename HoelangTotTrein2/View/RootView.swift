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

private struct FooterView: View {
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

private struct HeaderPickerView: View {
  @EnvironmentObject var adviceStations: VariableBindable<AdviceStations>

  var body: some View {
    HStack {
      Button(action: {
        _ = App.travelService.travelFromCurrentLocation()
      }) {
        Image(systemName: "location").padding()
      }.foregroundColor(Color.white)
      VStack(alignment: .leading) {
        StationPicker(picker: .from, stationName: self.adviceStations.value.from)
          .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
        StationPicker(picker: .to, stationName: self.adviceStations.value.to)
          .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))

      }.padding([.top, .bottom])
      Spacer()
      Button(action: {
        App.travelService.switchFromTo()
      }) {
        Image(systemName: "arrow.up.arrow.down").padding()
      }.foregroundColor(Color.white)

    }.background(Color.black.opacity(0.6))
  }
}

private struct StationPicker: View {
  let picker: PickerState
  let stationName: String?

  @State var showStationList: Bool = false
  @EnvironmentObject var stations: VariableBindable<Stations>
  @EnvironmentObject var mostUsedStations: VariableBindable<MostUsedStations>

  var body: some View {
    HStack(alignment: .lastTextBaseline) {
      Text("\(picker.description):")
        .foregroundColor(Color.white)
        .font(Font.footnote)
      Button(action: {
        self.showStationList.toggle()
      }) {
        Text(stationName ?? "[Pick Station]")
          .foregroundColor(Color.white)
          .font(Font.system(size: 21).bold())
      }
    }.sheet(isPresented: $showStationList, onDismiss: nil) {
      StationsList(picker: self.picker, showStationList: self.$showStationList)
        .environmentObject(self.stations)
        .environmentObject(self.mostUsedStations)
    }
  }
}

private struct AdvicesScrollView: View {
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
      ForEach(self.advices.value?.advices ?? [], id: \.id) { advice in
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

  func formattedString(_ departure: Date?) -> String? {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return departure.flatMap {
      formatter.string(from: $0)
    }
  }

  func duration(_ duration: TimeInterval?) -> String? {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return duration.flatMap {
      formatter.string(from: $0)
    }
  }

  func collaspedListItem(advice: Advice) -> some View {
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
        List(advices.value?.advices ?? []) {
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

struct ActivityIndicator: UIViewRepresentable {
  @Binding var isAnimating: Bool
  let style: UIActivityIndicatorView.Style

  func makeUIView(context _: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
    UIActivityIndicatorView(style: style)
  }

  func updateUIView(_ uiView: UIActivityIndicatorView, context _: UIViewRepresentableContext<ActivityIndicator>) {
    isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
  }
}

private func TrackView(plannedTrack: String?, actualTrack: String?) -> Text {
  Text(actualTrack ?? plannedTrack ?? "_")
    .foregroundColor(actualTrack != nil && actualTrack != plannedTrack ? .red : nil)
}

private func FareTimeView(fareTime: FareTime, font _: Font = Font.body) -> Text {
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm"

  return Text(formatter.string(from: fareTime.actual))
    .foregroundColor(fareTime.delay != nil ? .red : nil)
}

private struct AdviceView: View {
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

private struct ModalityTypes: View {
  let legs: [Leg]

  var body: some View {
    HStack(alignment: .center) {
      ForEach(legs, id: \.hashValue) { leg in
        Text(leg.product.shortCategoryName)
      }
    }
  }
}

private struct LegView: View {
  let leg: Leg

  var body: some View {
    HStack(alignment: .center) {
      Image("connection")
      VStack(spacing: 7) {
        LegPlaceView(legPlace: leg.origin)
        LegPlaceView(legPlace: leg.destination)
      }
    }
  }
}

private struct CollapsedLegsView: View {
  let legs: [Leg]

  private func single() -> some View {
    VStack {
      LegPlaceView(legPlace: legs.first!.origin)
      LegPlaceView(legPlace: legs.first!.destination)
    }
  }

  private func multiple() -> some View {
    VStack(alignment: .leading) {
      LegPlaceView(legPlace: legs.first!.origin)
      ForEach(legs.dropLast().dropFirst(), id: \.name) { leg in
        LegPlaceView(legPlace: leg.origin)
      }
      LegPlaceView(legPlace: legs.last!.destination)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      if legs.count > 1 {
        multiple()
      } else {
        single()
      }
    }
  }
}

private struct LegsView: View {
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

extension CrowdForecast {
  var fullBars: Int {
    switch self {
    case .high:
      return 3
    case .medium:
      return 2
    case .low:
      return 1
    case .unknown:
      return 0
    }
  }

  var color: Color {
    switch self {
    case .high:
      return .red
    case .medium:
      return .orange
    case .low:
      return .green
    case .unknown:
      return .gray
    }
  }
}

private struct CrowdForecastView: View {
  let crowdForecast: CrowdForecast?

  func image(name: String) -> some View {
    Image(systemName: name)
      .resizable()
      .frame(width: 5, height: 10)
  }

  var fullBars: Int {
    crowdForecast?.fullBars ?? 0
  }

  var color: Color {
    crowdForecast?.color ?? .gray
  }

  var body: some View {
    HStack(spacing: 3) {
      if crowdForecast == nil || crowdForecast == .unknown {
        EmptyView()
      } else {
        ForEach(0 ..< fullBars) { _ in
          self.image(name: "rectangle.fill")
            .foregroundColor(self.color)
        }

        ForEach(0 ..< (3 - fullBars)) { _ in
          self.image(name: "rectangle")
            .foregroundColor(.gray)
        }
      }
    }
  }
}

private struct LegPlaceView: View {
  let legPlace: LegPlace

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      FareTimeView(fareTime: legPlace.time)
      Text(legPlace.name)
        .font(Font.headline.bold())
      DelayTextView(legPlace: legPlace)

      Spacer()

      TrackView(plannedTrack: legPlace.plannedTrack, actualTrack: legPlace.actualTrack)
        .font(Font.body)
    }
  }
}

private func DelayTextView(legPlace: LegPlace) -> some View {
  let formatter = DateComponentsFormatter()
  formatter.allowedUnits = [.minute]
  let delay = legPlace.time.delay
  let offset = delay.flatMap { formatter.string(from: $0) }

  return IfLet(offset) { offset in
    Text("+ \(offset)m")
      .foregroundColor(Color.red)
  }
}

func IfLet<ValueType, TrueContent: View, FalseContent: View>(_ value: ValueType?, _ yay: (ValueType) -> TrueContent, _: () -> FalseContent) -> some View {
  Group {
    if value != nil {
      yay(value!)
    } else {
      EmptyView()
    }
  }
}

func IfLet<ValueType, TrueContent: View>(_ value: ValueType?, _ yay: (ValueType) -> TrueContent) -> some View {
  IfLet(value, yay) {
    EmptyView()
  }
}

extension Advice: Identifiable {
  public var id: Int {
    hashValue
  }
}
