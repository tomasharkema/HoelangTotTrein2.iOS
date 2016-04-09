//
//  StepView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 13-03-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit

struct StepViewModel {
//
//  enum Type {
//    case Begin
//    case End
//  }

  let fromStation: String
  let toStation: String
  let fromSpoor: String
  let toSpoor: String
  let fromTime: String
  let toTime: String
//  let type: Type
}

class StepView: UIView {

  @IBOutlet weak private var fromStationLabel: UILabel!
  @IBOutlet weak private var fromSpoorLabel: UILabel!
  @IBOutlet weak var fromTime: UILabel!
  @IBOutlet weak var toStationLabel: UILabel!
  @IBOutlet weak var toSpoorLabel: UILabel!
  @IBOutlet weak var toTime: UILabel!

  var viewModel: StepViewModel! {
    didSet {
      fromStationLabel.text = viewModel.fromStation
      fromSpoorLabel.text = viewModel.fromSpoor
      fromTime.text = viewModel.fromTime
      toStationLabel.text = viewModel.toStation
      toSpoorLabel.text = viewModel.toSpoor
      toTime.text = viewModel.toTime
    }
  }

}
