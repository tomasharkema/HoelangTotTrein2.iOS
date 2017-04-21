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

func formatTime(_ date: Date) -> String {
  let format = DateFormatter()
  format.dateFormat = "HH:mm"
  return format.string(from: date)
}

class InterfaceController: WKInterfaceController {

  @IBOutlet var platformLabel: WKInterfaceLabel!
  @IBOutlet var fromButton: WKInterfaceButton!
  @IBOutlet var toButton: WKInterfaceButton!
  @IBOutlet var timerLabel: WKInterfaceTimer!
  @IBOutlet var tickerContainer: WKInterfaceGroup!
  @IBOutlet var loadingLabel: WKInterfaceLabel!
  @IBOutlet var delayLabel: WKInterfaceLabel!

  var oneMinuteToGoTimer: Timer?

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    adviceDidChange(advice: nil)
  }

  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
//    NotificationCenter.default.addObserver(self, selector: #selector(adviceDidChange), name: NSNotification.Name(rawValue: AdvicesDidChangeNotification), object: nil)
    (WKExtension.shared().delegate as? ExtensionDelegate)?.requestInitialState { error in
      print("INITIAL STATE WITH: \(error)")
      self.adviceDidChange(advice: nil)
    }

    WatchApp.storageAttachment.attach()
    WatchApp.travelService.attach()
    _ = WatchApp.travelService.fetchStations()

    _ = Observable.merge([WatchApp.travelService.currentAdviceOnScreenObservable, WatchApp.travelService.currentAdviceObservable])
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] advice in
        guard let advice = advice else { return }
        print(advice)
        let fromStation = WatchApp.travelService.find(stationCode: advice.request.from)
        let toStation = WatchApp.travelService.find(stationCode: advice.request.to)
//        whenBoth(fromStation, toStation)
//          .then { [weak self] (from, to) in
          self?.adviceDidChange(advice: advice)//, from: from, to: to)
//        }
      })

    super.willActivate()
  }

  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
  }

  var previousAdvice: Advice?

  func adviceDidChange(advice: Advice?) {
    guard let advice = advice else {
      loadingLabel.setHidden(false)
      tickerContainer.setHidden(true)
      return
    }

    if let _ = advice.vertrekVertraging, previousAdvice?.vertrekVertraging != advice.vertrekVertraging {
      WKInterfaceDevice.current().play(.failure)
    }

    previousAdvice = advice

    fromButton.setTitle("\(formatTime(advice.vertrek.actualDate))\n\(advice.startStation ?? "")")
    toButton.setTitle("\(advice.endStation ?? "")\n\(formatTime(advice.aankomst.actualDate))")
    timerLabel.setDate(advice.vertrek.actualDate)
    timerLabel.start()

    platformLabel.setText(advice.vertrekSpoor)
    delayLabel.setText(advice.vertrekVertraging)

    loadingLabel.setHidden(true)
    tickerContainer.setHidden(false)

    let finished = advice.vertrek.actualDate.timeIntervalSinceNow
    oneMinuteToGoTimer?.invalidate()

    let oneMinuteToGoOffset = finished - 60
    if oneMinuteToGoOffset > 60 {
      oneMinuteToGoTimer = Timer.scheduledTimer(timeInterval: oneMinuteToGoOffset, target: self, selector: #selector(oneMinuteToGo), userInfo: nil, repeats: false)
    }
  }

  @objc func oneMinuteToGo() {
    WKInterfaceDevice.current().play(.directionUp)
  }
  
}
