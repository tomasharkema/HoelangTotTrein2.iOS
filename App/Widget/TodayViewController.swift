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

class TodayViewController: UIViewController, NCWidgetProviding {
        
  @IBOutlet private weak var timerLabel: UILabel!
  @IBOutlet private weak var fromLabel: UILabel!
  @IBOutlet private weak var toLabel: UILabel!

  private var currentAdvice: HoelangTotTreinCore.State<Advice?> = .loading
  private var heartBeatToken: HeartBeat.Token?

  private var dateFormatter: DateComponentsFormatter = {
    let dateFormatter = DateComponentsFormatter()
    dateFormatter.allowedUnits = [.hour, .minute, .second]
    return dateFormatter
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    App.storageAttachment
    _ = App.travelService.fetchStations()

    bind(\.currentAdvice, to: App.travelService.currentAdvice)

    let fromVariable: Variable<String> = App.travelService.currentAdvice.map { advice in
      guard let advice = advice.value.flatMap({ $0 }) else {
        return ""
      }
      let fromPlatform = advice.vertrekSpoor.map { "(\($0)) " } ?? ""
      return "\(fromPlatform)\(advice.startStation ?? "")"
    }
    fromLabel.bind(\.text, to: fromVariable)

    let toVariable: Variable<String> = App.travelService.currentAdvice.map { advice in
      guard let advice = advice.value.flatMap({ $0 }) else {
        return ""
      }
      let toPlatform = advice.aankomstSpoor.map { "(\($0)) " } ?? ""
      return "\(toPlatform)\(advice.endStation ?? "")"
    }
    toLabel.bind(\.text, to: toVariable)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    heartBeatToken = nil
    heartBeatToken = App.heartBeat.register(type: .repeating(interval: 1)) { [weak self] _ in
      self?.tick()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    heartBeatToken = nil
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
    guard let advice = currentAdvice.value.flatMap({ $0 }) else { return }
    timerLabel.text = dateFormatter.string(from: Date(), to: advice.vertrek.actual)
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
