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
  @IBOutlet private weak var minutesLabel: TimeLabel!
  @IBOutlet private weak var secondsLabel: TimeLabel!
  @IBOutlet private weak var stepsStackView: UIStackView!
  @IBOutlet private weak var tickerContainer: UIView!
  @IBOutlet private weak var modalityLabel: UILabel!

  override func prepareForReuse() {
    super.prepareForReuse()

    minutesLabel.stopTimer()
    secondsLabel.stopTimer()
  }

  var advice: Advice? {
    didSet {
      renderInfo()

      if let date = advice?.vertrek.actual, (Calendar.current.dateComponents([.hour], from: Date(), to: date).hour ?? -1) < 1 {
        minutesLabel.format = [.m]
        secondsLabel.format = [.s]
      } else {
        minutesLabel.format = [.h]
        secondsLabel.format = [.m, .customString(":"), .s]
      }

      minutesLabel.date = advice?.vertrek.actual
      secondsLabel.date = advice?.vertrek.actual

      minutesLabel.didReachNulSecondsHandler = {
        
      }
      secondsLabel.didReachNulSecondsHandler = {

      }
    }
  }

  func renderInfo() {
    guard let advice = advice else {
      return
    }

    let interval = Calendar.current.dateComponents([.second], from: Date(), to: advice.vertrek.actual).second ?? -1

    if interval > 0 {
      tickerContainer.alpha = 1
      statusMessageLabel.text = advice.status.alertDescription
    } else {
      tickerContainer.alpha = 0.2
      statusMessageLabel.text = R.string.localization.departed()
    }

    platformLabel.text = advice.vertrekSpoor.map { R.string.localization.platform($0) }
    aankomstVertragingLabel.text = advice.vertrekVertraging.map { R.string.localization.arrival($0) }

    modalityLabel.text = advice.reisDeel.map {
      $0.modalityType.abbriviation
    }.joined(separator: " > ")

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
    case .vertraagd:
      return R.string.localization.delayed()
    case .nietOptimaal:
      return R.string.localization.notOptimal()
    case .volgensPlan:
      return R.string.localization.onTime()
    case .gewijzigd:
      return R.string.localization.changed()
    default:
      return R.string.localization.somethingsWrong()
    }
  }
}
