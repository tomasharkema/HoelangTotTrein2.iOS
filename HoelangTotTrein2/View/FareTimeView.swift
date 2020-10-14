//
//  FareTimeView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

func FareTimeView(fareTime: FareTime, font _: Font = Font.body) -> Text {
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm"

  return Text(formatter.string(from: fareTime.actual))
    .foregroundColor(fareTime.delay != nil ? .red : nil)
}
