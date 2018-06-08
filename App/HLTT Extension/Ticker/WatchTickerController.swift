//
//  InterfaceController.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import HoelangTotTreinAPIWatch
import HoelangTotTreinCoreWatch
import RxSwift

class WatchTickerController: WKInterfaceController {

  @IBOutlet private var platformLabel: WKInterfaceLabel!
  @IBOutlet private var fromButton: WKInterfaceButton!
  @IBOutlet private var toButton: WKInterfaceButton!
  @IBOutlet private var timerLabel: WKInterfaceTimer!
  @IBOutlet private var tickerContainer: WKInterfaceGroup!
  @IBOutlet private var loadingLabel: WKInterfaceLabel!
  @IBOutlet private var delayLabel: WKInterfaceLabel!

  private var bag: DisposeBag!

  private var oneMinuteToGoTimer: Timer?

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    adviceDidChange(advice: nil)
  }

  override func willActivate() {
    super.willActivate()

    (WKExtension.shared().delegate as? ExtensionDelegate)?.requestInitialState { error in
      print("INITIAL STATE WITH: \(error)")
    }

    WatchApp.storageAttachment.attach()
    WatchApp.travelService.attach()
    _ = WatchApp.travelService.fetchStations()

    bag = DisposeBag()

    Observable.merge([WatchApp.travelService.currentAdviceOnScreenObservable, WatchApp.travelService.currentAdviceObservable])
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] advice in
        guard let advice = advice else { return }
        self?.adviceDidChange(advice: advice)
      })
      .disposed(by: bag)
  }

  override func didDeactivate() {
    super.didDeactivate()
    bag = nil
  }

  private var previousAdvice: Advice?

  private func adviceDidChange(advice: Advice?) {
    guard let advice = advice else {
      loadingLabel.setHidden(false)
      tickerContainer.setHidden(true)
      return
    }

    if let _ = advice.vertrekVertraging, previousAdvice?.vertrekVertraging != advice.vertrekVertraging {
      WKInterfaceDevice.current().play(.failure)
    }

    previousAdvice = advice

    fromButton.setTitle("\(formatTime(advice.vertrek.actual))\n\(advice.startStation ?? "")")
    toButton.setTitle("\(advice.endStation ?? "")\n\(formatTime(advice.aankomst.actual))")

    if advice.vertrek.actual > Date() {
      timerLabel.setDate(advice.vertrek.actual)
      timerLabel.start()
    } else {
      timerLabel.setDate(Date())
      timerLabel.stop()
    }

    platformLabel.setText(advice.vertrekSpoor)
    delayLabel.setText(advice.vertrekVertraging)

    loadingLabel.setHidden(true)
    tickerContainer.setHidden(false)

    let finished = advice.vertrek.actual.timeIntervalSinceNow
    oneMinuteToGoTimer?.invalidate()

    let oneMinuteToGoOffset = finished - 60
    if oneMinuteToGoOffset > 60 {
      oneMinuteToGoTimer = Timer.scheduledTimer(timeInterval: oneMinuteToGoOffset, target: self, selector: #selector(oneMinuteToGo), userInfo: nil, repeats: false)
    }
  }

  @objc func oneMinuteToGo() {
    WKInterfaceDevice.current().play(.directionUp)
  }

  private func formatTime(_ date: Date) -> String {
    let format = DateFormatter()
    format.dateFormat = "HH:mm"
    return format.string(from: date)
  }
}
