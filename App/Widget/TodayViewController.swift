//
//  TodayViewController.swift
//  Widget
//
//  Created by Tomas Harkema on 20-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import Bindable
import Promissum
import HoelangTotTreinCore
import HoelangTotTreinAPI
import NotificationCenter
import AFDateHelper

class TodayViewController: UIViewController, NCWidgetProviding {
        
  @IBOutlet private weak var timerLabel: UILabel!
  @IBOutlet private weak var fromLabel: UILabel!
  @IBOutlet private weak var toLabel: UILabel!

  private var currentAdvice: Advice?
  private var heartBeatToken: HeartBeat.Token?

  override func viewDidLoad() {
    super.viewDidLoad()

//    WidgetApp.storageAttachment.attach()
    _ = WidgetApp.travelService.fetchStations()

    bind(\.currentAdvice, to: WidgetApp.travelService.currentAdvice)

    let fromVariable: Variable<String> = WidgetApp.travelService.currentAdvice.map { advice in
      guard let advice = advice else {
        return ""
      }
      let fromPlatform = advice.vertrekSpoor.map { "(\($0)) " } ?? ""
      return "\(fromPlatform)\(advice.startStation ?? "")"
    }
    fromLabel.bind(\.text, to: fromVariable)

    let toVariable: Variable<String> = WidgetApp.travelService.currentAdvice.map { advice in
      guard let advice = advice else {
        return ""
      }
      let toPlatform = advice.aankomstSpoor.map { "(\($0)) " } ?? ""
      return "\(toPlatform)\(advice.endStation ?? "")"
    }
    toLabel.bind(\.text, to: toVariable)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    heartBeatToken = WidgetApp.heartBeat.register(type: .repeating(interval: 1)) { [weak self] _ in
      self?.tick()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let heartBeatToken = heartBeatToken {
      WidgetApp.heartBeat.unregister(token: heartBeatToken)
      self.heartBeatToken = nil
    }
  }

//  private func render(advice: Advice, from: Station, to: Station) {
//    currentAdvice = advice
//    let fromPlatform = advice.vertrekSpoor.map { "(\($0)) " } ?? ""
//    let toPlatform = advice.aankomstSpoor.map { "(\($0)) " } ?? ""
//
//    fromLabel.text = "\(fromPlatform)\(advice.startStation ?? "")"
//    toLabel.text = "\(toPlatform)\(advice.endStation ?? "")"
//  }

  private func tick() {
    guard let advice = currentAdvice else { return }
    let offset = advice.vertrek.actual.timeIntervalSince(Date())
    let difference = Date(timeIntervalSince1970: max(0, offset) - 60*60)

    timerLabel.text = difference.toString(format: .custom("mm:ss"))
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    // Perform any setup necessary in order to update the view.
      
    // If an error is encountered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData
      
    completionHandler(.newData)
  }
  
  @IBAction func pressedWidget(_ sender: Any) {
    extensionContext?.open(URL(string: "hltt://")!, completionHandler: nil)
  }
}
