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

    let offset = advice.vertrek.actualDate.timeIntervalSinceDate(NSDate())
    let difference = NSDate(timeIntervalSince1970: offset - 60*60)
    let timeBeforeColonString: String
    let timeAfterColonString: String
    if difference.hour() > 0 {
      timeBeforeColonString = difference.toString(format: .Custom("H"))
      timeAfterColonString = difference.toString(format: .Custom("mm"))

    } else {
      timeBeforeColonString = difference.toString(format: .Custom("mm"))
      timeAfterColonString = difference.toString(format: .Custom("ss"))
    }

    minutesLabel.text = timeBeforeColonString
    secondsLabel.text = timeAfterColonString
//    timeContainerView.hidden = false
//    nextView.hidden = false
//    nextViewBlur.hidden = false
  }

  func renderInfo() {
    guard let advice = advice else {
      return
    }
//    extraLabel.text = advice.extraMessage
    statusMessageLabel.text = advice.status.alertDescription
    platformLabel.text = advice.vertrekSpoor.map { "platform \($0)" }
    aankomstVertragingLabel.text = advice.vertrekVertraging.map { "arrival: \($0)" }
//    stepsLabel.text = advice.stepsMessage
    renderSteps(advice.stepModels)
  }

  private func renderSteps(stepModels: [StepViewModel]) {
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
