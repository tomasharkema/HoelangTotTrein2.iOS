//
//  StationsList.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23/07/2019.
//  Copyright © 2019 Tomas Harkema. All rights reserved.
//

import SwiftUI
#if canImport(API)
import API
#endif
#if canImport(APIWatch)
import APIWatch
#endif
#if canImport(Core)
import Core
#endif
#if canImport(CoreWatch)
import CoreWatch
#endif
import Bindable

struct StationsList: View {

  let picker: PickerState
  @EnvironmentObject var stations: VariableBindable<Stations>
  @EnvironmentObject var mostUsedStations: VariableBindable<MostUsedStations>
  @Binding var showStationList: Bool

  @State private var searchQuery = ""
  @State private var closeStations = [Station]()
  @State private var searchResults = [Station]()

  @State private var isSearching = false

  private func searchBar(update: @escaping (String) -> ()) -> some View {
    Section(header: SearchBar(text: self.$searchQuery, update: update).edgesIgnoringSafeArea(.all)) {
      if !searchResults.isEmpty {
        ForEach(searchResults, id: \.id) { station in
          StationListButton(picker: self.picker, station: station, close: self.close)
        }
      } else {
        EmptyView()
      }
    }
  }

  private func listContent() -> some View {
    Group {
      if !closeStations.isEmpty {
        Section(header: Text("Nearby")) {
          ForEach(closeStations, id: \.id) { station in
            StationListButton(picker: self.picker, station: station, close: self.close)
          }
        }
      } else {
        EmptyView()
      }
      Section(header: Text("Most Used")) {
        ForEach(mostUsedStations.value.stations, id: \.id) { station in
          StationListButton(picker: self.picker, station: station, close: self.close)
        }
      }

      Section(header: Text("Stations")) {
        ForEach(stations.value, id: \.id) { station in
          StationListButton(picker: self.picker, station: station, close: self.close)
        }
      }
    }
  }

  private func close() {
    self.showStationList = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.searchQuery = ""
    }
  }

  var body: some View {
    NavigationView {
      List {
        searchBar(update: { string in
          App.travelService.find(stationNameContains: string)
            .then { stations in
              self.searchResults = stations
            }
        })

        if searchQuery.isEmpty {
          listContent()
        } else {
          EmptyView()
        }

      }
      .navigationBarTitle("\(picker.description)")
        .navigationBarItems(leading: Button(action: {
          self.close()
        }) {
          Text("Cancel")
        })
        .onAppear {
          App.travelService.getCloseStations()
            .then { stations in
              self.closeStations = stations
          }
      }
    }

  }
}

private struct StationListButton: View {
  let picker: PickerState
  let station: Station
  let close: () -> ()

  var body: some View {
    Button(action: {
      App.travelService.setStation(self.picker, byPicker: true, uicCode: self.station.UICCode)
      self.close()
    }) {
      Text(station.name)
    }
  }
}

struct SearchBar: UIViewRepresentable {

  @Binding var text: String
  let update: (String) -> ()

  class Coordinator: NSObject, UISearchBarDelegate {

    let update: (String) -> ()

    init(update: @escaping (String) -> ()) {
      self.update = update
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      update(searchText)
    }
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(update: {
      self.text = $0
      self.update($0)
    })
  }

  func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
    let searchBar = UISearchBar(frame: .zero)
    searchBar.delegate = context.coordinator
    return searchBar
  }

  func updateUIView(_ uiView: UISearchBar,
                    context: UIViewRepresentableContext<SearchBar>) {
    uiView.text = text
  }
}
