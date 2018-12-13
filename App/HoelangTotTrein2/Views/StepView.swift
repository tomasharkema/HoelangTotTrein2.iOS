//
//  StepView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 13-03-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit

struct StepViewModel {
  let fromStation: String
  let toStation: String
  let fromSpoor: String
  let toSpoor: String
  let fromTime: String
  let toTime: String
  let destination: String
}

class StepView: UIView {

  @IBOutlet weak private var fromStationLabel: UILabel!
  @IBOutlet weak private var fromSpoorLabel: UILabel!
  @IBOutlet weak private var fromTime: UILabel!
  @IBOutlet weak private var toStationLabel: UILabel!
  @IBOutlet weak private var toSpoorLabel: UILabel!
  @IBOutlet weak private var toTime: UILabel!

  var viewModel: StepViewModel! {
    didSet {
      fromStationLabel.text = "\(viewModel.fromStation) > \(viewModel.destination)"
      fromSpoorLabel.text = viewModel.fromSpoor
      fromTime.text = viewModel.fromTime
      fromTime.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
      toStationLabel.text = viewModel.toStation
      toSpoorLabel.text = viewModel.toSpoor
      toTime.text = viewModel.toTime
      toTime.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
    }
  }

}
