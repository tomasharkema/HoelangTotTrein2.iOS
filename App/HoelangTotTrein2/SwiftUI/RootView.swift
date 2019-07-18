//
//  RootView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 17/07/2019.
//  Copyright © 2019 Tomas Harkema. All rights reserved.
//

import SwiftUI
import HoelangTotTreinAPI
import HoelangTotTreinCore
import Bindable

extension EdgeInsets {
  init(leadingAndTrailing: Length) {
    self.init(top: 0, leading: leadingAndTrailing, bottom: 0, trailing: leadingAndTrailing)
  }
}

struct RootView : View {

  @ObjectBinding var adviceStations: VariableBindable<AdviceStations>
  @ObjectBinding var advices: VariableBindable<Advices?>
  
  var body: some View {
    HStack {
      VStack(alignment: HorizontalAlignment.center) {
        HeaderPickerView(adviceStations: self.adviceStations).background(Color.black)
        AdvicesScrollView(advices: advices)
      }
    }
  }
}

struct HeaderPickerView: View {

  @ObjectBinding var adviceStations: VariableBindable<AdviceStations>

  var body: some View {
    VStack(alignment: .center) {
      HStack {
          Spacer()
      }
      StationPicker(stationName: adviceStations.value.from) {
        _ = App.travelService.setStation(.from, byPicker: true, uicCode: UicCode(rawValue: "8400319"))
      }.padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
      StationPicker(stationName: adviceStations.value.to) {
        _ = App.travelService.setStation(.to, byPicker: true, uicCode: UicCode(rawValue: "8400388"))
      }.padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
    }
  }
}

struct StationPicker: View {
  let stationName: String?
  let action: () -> ()
  var body: some View {
    Button(action: action) {
      Text(stationName ?? "[Picker Station]").foregroundColor(Color.white)
    }
  }
}

struct AdvicesScrollView: View {

  @ObjectBinding var advices: VariableBindable<Advices?>
  
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        ForEach(self.advices.value ?? [].filter({ $0.departure.actual.timeIntervalSinceNow > 0 }), id: \.checksum) { advice in
           AdviceView(advice: advice, geometry: geometry)
        }
      }
    }
  }
}

struct AdviceView: View {
  
  let advice: Advice
  let geometry: GeometryProxy
  
  var body: some View {
    VStack(alignment: .center) {
      Spacer()
      HStack(alignment: .center) {
        VStack {
          HStack(alignment: .center) {
            Text("Spoor \(advice.startStation?.plannedTrack ?? "")")
            Spacer()
            ModalityTypes(types: advice.legs.map {
              $0.product.shortCategoryName
            })
          }.padding(EdgeInsets(leadingAndTrailing: 10))

          Ticker(date: advice.departure.actual)
            .frame(width: geometry.size.width)

          HStack {
            Spacer()
            Text(advice.status.alertDescription)
          }.padding(EdgeInsets(leadingAndTrailing: 10))
        }
      }
      Spacer()
      LegsView(legs: advice.legs)
    }.frame(width: geometry.size.width, height: geometry.size.height)
  }
}

struct Ticker: View {

  let date: Date

  let formatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.second, .minute, .hour]
    return formatter
  }()

  @EnvironmentObject var timerHolder: TimerHolder

  var body: some View {
    Text(formatter.string(from: date.timeIntervalSinceNow) ?? "")
      .font(Font.system(size: 100).monospacedDigit())
  }
}

struct ModalityTypes: View {

  let types: [String]

  var body: some View {
    HStack(alignment: .center) {
      ForEach(types, id: \.hashValue) {
        Text($0)
      }
    }
  }
}

struct LegsView: View {

  let legs: [Leg]

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(legs, id: \.name) { leg in
        VStack {
          HStack {
            Spacer()
            Text("\(leg.product.shortCategoryName) ri. \(leg.direction ?? "")")
          }
          LegPlaceView(legPlace: leg.origin)
          LegPlaceView(legPlace: leg.destination)
        }.padding()
      }
    }
  }
}

struct LegPlaceView: View {

  let legPlace: LegPlace

  let formatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f
  }()

  var body: some View {
    HStack(alignment: .top) {
      Text(formatter.string(from: legPlace.actualDateTime ?? legPlace.plannedDateTime)).font(Font.body.monospacedDigit())
      Text(legPlace.name).font(Font.body.bold())
      Spacer()
      Text(legPlace.plannedTrack ?? "").font(Font.body.monospacedDigit())
    }
  }
}

