//
//  AdviceCell.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 09-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit
import HoelangTotTreinAPI
import HoelangTotTreinCore

class AdviceCell: UICollectionViewCell {

  @IBOutlet private weak var platformLabel: UILabel!
  @IBOutlet private weak var aankomstVertragingLabel: UILabel!
  @IBOutlet private weak var statusMessageLabel: UILabel!
  @IBOutlet private weak var minutesLabel: TimeLabel!
  @IBOutlet private weak var secondsLabel: TimeLabel!
  @IBOutlet private weak var stepsStackView: UIStackView!
  @IBOutlet private weak var tickerContainer: UIView!
  @IBOutlet private weak var modalityLabel: UILabel!

  private var heartBeatToken: HeartBeat.Token?

  override func prepareForReuse() {
    super.prepareForReuse()

    heartBeatToken = nil
    
    minutesLabel.isActive = false
    secondsLabel.isActive = false
  }

  var advice: Advice? {
    didSet {
      renderInfo()
      minutesLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 80, weight: .thin)
      secondsLabel.isHidden = true
//      minutesLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 150, weight: .thin)
//      secondsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 60, weight: .thin)

      let minutesFormatter = DateComponentsFormatter()
      minutesFormatter.allowedUnits = [.second, .minute, .hour]
//      minutesFormatter.unitsStyle = .abbreviated
      minutesLabel.formatter = minutesFormatter
      let secondsFormatter = DateComponentsFormatter()
      secondsFormatter.allowedUnits = []
      secondsLabel.formatter = secondsFormatter


//      if let date = advice?.vertrek.actual, (Calendar.current.dateComponents([.hour], from: Date(), to: date).hour ?? -1) < 1 {
//        let minutesFormatter = DateComponentsFormatter()
//        minutesFormatter.allowedUnits = [.minute, .hour]
//        minutesFormatter.maximumUnitCount = 1
//        minutesLabel.formatter = minutesFormatter
//        let secondsFormatter = DateComponentsFormatter()
//        secondsFormatter.allowedUnits = [.second, .minute]
////        secondsFormatter.maximumUnitCount = 1
//        secondsLabel.formatter = secondsFormatter
//      } else {
//        let minutesFormatter = DateComponentsFormatter()
//        minutesFormatter.allowedUnits = [.hour]
////        minutesFormatter.maximumUnitCount = 1
//        minutesLabel.formatter = minutesFormatter
//        let secondsFormatter = DateComponentsFormatter()
//        secondsFormatter.allowedUnits = [.minute, .second]
////        secondsFormatter.maximumUnitCount = 1
//        secondsLabel.formatter = secondsFormatter
//      }

      minutesLabel.date = advice?.vertrek.actual
      secondsLabel.date = advice?.vertrek.actual
      minutesLabel.isActive = true
      secondsLabel.isActive = true
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
