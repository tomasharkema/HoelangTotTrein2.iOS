//
//  AdviceCell.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 09-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit
import HoelangTotTreinAPI

class AdviceCell: UICollectionViewCell {

  @IBOutlet private weak var platformLabel: UILabel!
  @IBOutlet private weak var aankomstVertragingLabel: UILabel!
  @IBOutlet private weak var statusMessageLabel: UILabel!
  @IBOutlet private weak var minutesLabel: UILabel!
  @IBOutlet private weak var secondsLabel: UILabel!
  @IBOutlet private weak var stepsStackView: UIStackView!
  @IBOutlet private weak var tickerContainer: UIView!

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

    let interval = advice.vertrek.actualDate.timeIntervalSince(Date())

    if interval > 0 {
      tickerContainer.alpha = 1
      statusMessageLabel.text = advice.status.alertDescription
    } else {
      tickerContainer.alpha = 0.2
      statusMessageLabel.text = R.string.localization.departed()
    }

    platformLabel.text = advice.vertrekSpoor.map { R.string.localization.platform($0) }
    aankomstVertragingLabel.text = advice.vertrekVertraging.map { R.string.localization.arrival($0) }
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

extension FareStatus {
  var alertDescription: String {
    switch self {
    case .Vertraagd:
      return R.string.localization.delayed()
    case .NietOptimaal:
      return R.string.localization.notOptimal()
    case .VolgensPlan:
      return R.string.localization.onTime()
    case .Gewijzigd:
      return R.string.localization.changed()
    default:
      return R.string.localization.somethingsWrong()
    }
  }
}
