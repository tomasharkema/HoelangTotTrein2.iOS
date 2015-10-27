//
//  ViewController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import SegueManager
import AFDateHelper

class TickerViewController: ViewController {

  var fromStation: Station?
  var toStation: Station?

  var currentAdviceSubscription: ObservableSubject<Advice>?
  var currentAdviceRequestSubscription: ObservableSubject<AdviceRequest>?

  var timer: NSTimer?
  var currentAdvice: Advice?

  @IBOutlet weak var fromButton: UIButton!
  @IBOutlet weak var toButton: UIButton!
  @IBOutlet weak var timerLabel: UILabel!

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "tick:", userInfo: nil, repeats: true)

    App.travelService.startTimer()

    currentAdviceSubscription = App.travelService.currentAdviceObservable.subscribe { [weak self] advice in
      self?.currentAdvice = advice
      self?.render()
    }

    currentAdviceRequestSubscription = App.travelService.currentAdviceRequest.subscribe { [weak self] adviceRequest in
      self?.fromStation = adviceRequest.from
      self?.toStation = adviceRequest.to
      self?.fromButton.setTitle(adviceRequest.from?.name ?? NSLocalizedString("[Selecteer]", comment: "selecteer"), forState: UIControlState.Normal)
      self?.toButton.setTitle(adviceRequest.to?.name ?? NSLocalizedString("[Selecteer]", comment: "selecteer"), forState: UIControlState.Normal)
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    timer?.invalidate()
    timer = nil

    App.travelService.stopTimer()
    if let currentAdviceSubscription = currentAdviceSubscription {
      App.travelService.currentAdviceObservable.unsubscribe(currentAdviceSubscription)
    }
    if let currentAdviceRequestSubscription = currentAdviceRequestSubscription {
      App.travelService.currentAdviceRequest.unsubscribe(currentAdviceRequestSubscription)
    }
  }

  func showPickerController(state: PickerState) {

    segueManager.performSegue(R.segue.presentPickerSegue) { [weak self] (controller: PickerViewController) in

      controller.state = state
      controller.selectedStation = state == .From ? self?.fromStation : self?.toStation
      controller.successHandler = { [weak controller] station in
        App.travelService.setStation(state, station: station, byPicker: true)
        controller?.dismissViewControllerAnimated(true, completion: nil)
      }

      controller.cancelHandler = { [weak controller] in
        controller?.dismissViewControllerAnimated(true, completion: nil)
      }
    }
  }

  func tick(timer: NSTimer) {
    render()
  }

  func render() {
    if let currentAdvice = currentAdvice {
      let offset = currentAdvice.vertrek.actualDate.timeIntervalSinceDate(NSDate())
      let difference = NSDate(timeIntervalSince1970: offset - 60*60)

      let timeString: String
      if difference.hour() > 0 {
        timeString = difference.toString(format: .Custom("H:mm"))
      } else {
        timeString = difference.toString(format: .Custom("mm:ss"))
      }

      timerLabel.text = timeString
    }
  }

  @IBAction func fromButtonPressed(sender: AnyObject) {
    showPickerController(.From)
  }

  @IBAction func toButtonPressed(sender: AnyObject) {
    showPickerController(.To)
  }

  @IBAction func currentLocationPressed(sender: AnyObject) {
    App.locationService.requestAuthorization().then { state in
      App.travelService.travelFromCurrentLocation()
    }
  }

  @IBAction func switchPressed(sender: AnyObject) {
    App.travelService.switchFromTo()
  }


}

