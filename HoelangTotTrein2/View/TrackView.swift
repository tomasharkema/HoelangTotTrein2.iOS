//
//  TrackView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import Foundation
import SwiftUI

func TrackView(plannedTrack: String?, actualTrack: String?) -> Text {
  Text(actualTrack ?? plannedTrack ?? "_")
    .foregroundColor(actualTrack != nil && actualTrack != plannedTrack ? .red : nil)
}
