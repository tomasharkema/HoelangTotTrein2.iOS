//
//  AdviceCell.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 09-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import API
import Core
import UIKit

class AdviceCell: UICollectionViewCell {
  @IBOutlet private var platformLabel: UILabel!
  @IBOutlet private var aankomstVertragingLabel: UILabel!
  @IBOutlet private var statusMessageLabel: UILabel!
  @IBOutlet private var minutesLabel: TimeLabel!
  @IBOutlet private var stepsStackView: UIStackView!
  @IBOutlet private var tickerContainer: UIView!
  @IBOutlet private var modalityLabel: UILabel!

  private var heartBeatToken: HeartBeat.Token?

  override func prepareForReuse() {
    super.prepareForReuse()

    heartBeatToken = nil

    minutesLabel.isActive = false
  }

  var advice: Advice? {
    didSet {
      renderInfo()

      minutesLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 150, weight: .thin)

      let minutesFormatter = DateComponentsFormatter()
      minutesFormatter.allowedUnits = [.second, .minute, .hour]

      minutesLabel.formatter = minutesFormatter
      minutesLabel.date = advice?.departure.actual

      minutesLabel.isActive = true
    }
  }

  func renderInfo() {
    guard let advice = advice else {
      return
    }

    let interval = Calendar.current.dateComponents([.second], from: Date(), to: advice.departure.actual).second ?? -1

    if interval > 0 {
      tickerContainer.alpha = 1
      statusMessageLabel.text = "\(advice.status.alertDescription) | \(advice.legs.first?.crowdForecast?.rawValue ?? "UNKNOWN")"
    } else {
      tickerContainer.alpha = 0.2
      statusMessageLabel.text = R.string.localization.departed()
    }

    platformLabel.text = advice.vertrekSpoor.map { R.string.localization.platform($0) }

    aankomstVertragingLabel.text = advice.departure.delay.flatMap {
      let formatter = DateComponentsFormatter()
      formatter.unitsStyle = .abbreviated
      return formatter.string(from: $0).map { "+ \($0)" }
    } ?? advice.vertrekVertraging.map {
      R.string.localization.arrival($0)
    }

    modalityLabel.text = advice.legs.map(\.product.shortCategoryName).joined(separator: " > ")

    render(stepModels: advice.stepModels)
  }

  fileprivate func render(stepModels: [StepViewModel]) {
    stepsStackView.arrangedSubviews.forEach { view in
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
    rawValue
//    switch self {
//    case .:
//      return R.string.localization.delayed()
//    case .nietOptimaal:
//      return R.string.localization.notOptimal()
//    case .NORMAL:
//      return R.string.localization.onTime()
//    case .gewijzigd:
//      return R.string.localization.changed()
//    default:
//      return R.string.localization.somethingsWrong()
//    }
  }
}
