//
//  TodayViewController.swift
//  Widget
//
//  Created by Tomas Harkema on 20-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import RxSwift
import Promissum
import HoelangTotTreinAPI
import NotificationCenter
import AFDateHelper

class TodayViewController: UIViewController, NCWidgetProviding {
        
  @IBOutlet private weak var timerLabel: UILabel!
  @IBOutlet weak var fromLabel: UILabel!
  @IBOutlet weak var toLabel: UILabel!

  private var timer: Timer?

  override func viewDidLoad() {
    super.viewDidLoad()

    WidgetApp.storageAttachment.attach()
    WidgetApp.travelService.attach()
    _ = WidgetApp.travelService.fetchStations()

    _ = WidgetApp.travelService.currentAdviceObservable
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] advice in
        guard let advice = advice else { return }

        let fromStation = WidgetApp.travelService.find(stationCode: advice.request.from)
        let toStation = WidgetApp.travelService.find(stationCode: advice.request.to)
        whenBoth(fromStation, toStation)
          .then { /*[weak self]*/ let (from, to) = $0;
            self?.render(advice: advice, from: from, to: to)
          }
      })
  }

  private func render(advice: Advice, from: Station, to: Station) {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(tick), userInfo: advice, repeats: true)

    let fromPlatform = advice.vertrekSpoor.map { "(\($0)) " } ?? ""
    let toPlatform = advice.aankomstSpoor.map { "(\($0)) " } ?? ""

    fromLabel.text = "\(fromPlatform)\(advice.startStation ?? "")"
    toLabel.text = "\(toPlatform)\(advice.endStation ?? "")"
  }

  @objc func tick(timer: Timer) {
    guard let advice = timer.userInfo as? Advice else { return }
    let offset = advice.vertrek.actual.timeIntervalSince(Date())
    let difference = Date(timeIntervalSince1970: max(0, offset) - 60*60)

    timerLabel.text = difference.toString(format: .custom("mm:ss"))
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    // Perform any setup necessary in order to update the view.
      
    // If an error is encountered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData
      
    completionHandler(.newData)
  }
  
}
