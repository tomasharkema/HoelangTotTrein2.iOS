//
//  AdviceCell.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 09-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit

class AdviceCell: UICollectionViewCell {

  @IBOutlet weak var platformLabel: UILabel!
  @IBOutlet weak var aankomstVertragingLabel: UILabel!
  @IBOutlet weak var statusMessageLabel: UILabel!
  @IBOutlet weak var minutesLabel: UILabel!
  @IBOutlet weak var secondsLabel: UILabel!
  @IBOutlet weak var stepsStackView: UIStackView!

  var advice: Advice? {
    didSet {
      renderTimer()
      renderInfo()
    }
  }

  func renderTimer() {
    guard let advice = advice else {
      return
    }

    let offset = advice.vertrek.actualDate.timeIntervalSince(Date())
    let difference = Date(timeIntervalSince1970: max(0, offset) - 60*60)
    let timeBeforeColonString: String
    let timeAfterColonString: String

    if Calendar.current.component(.hour, from: difference) > 0 {
      timeBeforeColonString = difference.toString(format: .custom("H"))
      timeAfterColonString = difference.toString(format: .custom("mm"))

    } else {
      timeBeforeColonString = difference.toString(format: .custom("mm"))
      timeAfterColonString = difference.toString(format: .custom("ss"))
    }

    minutesLabel.text = timeBeforeColonString
    secondsLabel.text = timeAfterColonString
  }

  func renderInfo() {
    guard let advice = advice else {
      return
    }

    statusMessageLabel.text = advice.status.alertDescription
    platformLabel.text = advice.vertrekSpoor.map { "platform \($0)" }
    aankomstVertragingLabel.text = advice.vertrekVertraging.map { "arrival: \($0)" }
    renderSteps(advice.stepModels)
  }

  fileprivate func renderSteps(_ stepModels: [StepViewModel]) {
    stepsStackView.arrangedSubviews.forEach { [weak self] view in
      self?.stepsStackView.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    let views: [StepView] = stepModels.map {
      let view = R.nib.stepView.firstView(owner: nil)!
      view.viewModel = $0
      return view
    }
    views.forEach { [weak self] view in self?.stepsStackView.addArrangedSubview(view) }
  }
}
