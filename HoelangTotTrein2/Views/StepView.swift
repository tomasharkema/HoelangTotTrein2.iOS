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
  let direction: String?
  let product: String
}

class StepView: UIView {
  @IBOutlet private var fromStationLabel: UILabel!
  @IBOutlet private var fromSpoorLabel: UILabel!
  @IBOutlet private var fromTime: UILabel!
  @IBOutlet private var toStationLabel: UILabel!
  @IBOutlet private var toSpoorLabel: UILabel!
  @IBOutlet private var toTime: UILabel!
  @IBOutlet var destinationView: UILabel!

  var viewModel: StepViewModel! {
    didSet {
      fromStationLabel.text = viewModel.fromStation
      fromSpoorLabel.text = viewModel.fromSpoor
      fromTime.text = viewModel.fromTime
      fromTime.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
      toStationLabel.text = viewModel.toStation
      toSpoorLabel.text = viewModel.toSpoor
      toTime.text = viewModel.toTime
      toTime.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)

      let destinationText: [String] = [
        viewModel.product,
        viewModel.direction.map { "ri. \($0)" },
      ].compactMap { $0 }

      destinationView.text = destinationText.joined(separator: " ")
    }
  }
}
