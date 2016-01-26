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

  let AnimationInterval: NSTimeInterval = 0.5

  var fromStation: Station?
  var toStation: Station?

  var currentAdviceSubscription: ObservableSubject<Advice>?
  var currentAdviceRequestSubscription: ObservableSubject<AdviceRequest>?

  var nextAdviceSubscription: ObservableSubject<Advice>?

  var timer: NSTimer?
  var currentAdvice: Advice?

  var nextAdvice: Advice?

  var startTime: NSDate?

  @IBOutlet weak var backgroundView: UIImageView!

  @IBOutlet weak var fromButton: UIButton!
  @IBOutlet weak var toButton: UIButton!

  // cell things
  @IBOutlet weak var timerMinutesLabel: UILabel!
  @IBOutlet weak var timerSecondsLabel: UILabel!
  @IBOutlet weak var platformLabel: UILabel!
  @IBOutlet weak var aankomstVertraging: UILabel!
  @IBOutlet weak var statusMessageLabel: UILabel!
  @IBOutlet weak var extraLabel: UILabel!
  @IBOutlet weak var stepsLabel: UITextView!

  //next
  @IBOutlet weak var nextLabel: UILabel!
  @IBOutlet weak var nextView: UIView!
  @IBOutlet weak var nextDelayLabel: UILabel!

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    timer = NSTimer.scheduledTimerWithTimeInterval(AnimationInterval, target: self, selector: "tick:", userInfo: nil, repeats: true)

    App.travelService.startTimer()

    currentAdviceSubscription = App.travelService.currentAdviceObservable.subscribe { [weak self] advice in
      print("NEW ADVICE! \(advice)")
      self?.startTime = NSDate()
      self?.currentAdvice = advice
      self?.render()

      self?.extraLabel.text = advice.extraMessage
      self?.statusMessageLabel.text = advice.status.alertDescription
      self?.platformLabel.text = advice.vertrekSpoor.map { "Spoor \($0)" }
      self?.aankomstVertraging.text = advice.vertrekVertraging.map { "aankomst: \($0)" }
      self?.stepsLabel.text = advice.stepsMessage
    }

    nextAdviceSubscription = App.travelService.nextAdviceObservable.subscribe { [weak self] advice in
      self?.nextAdvice = advice
      self?.render()
    }

    currentAdviceRequestSubscription = App.travelService.currentAdviceRequest.subscribe { [weak self] adviceRequest in
      self?.fromStation = adviceRequest.from
      self?.toStation = adviceRequest.to
      self?.fromButton.setTitle(adviceRequest.from?.name ?? NSLocalizedString("[Selecteer]", comment: "selecteer"), forState: UIControlState.Normal)
      self?.toButton.setTitle(adviceRequest.to?.name ?? NSLocalizedString("[Selecteer]", comment: "selecteer"), forState: UIControlState.Normal)
    }

    render()
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
    segueManager.performSegue(R.segue.tickerViewController.presentPickerSegue) { [weak self] segue in

      let controller = segue.destinationViewController

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

      let leftBackgroundOffset: CGFloat
      if let startTime = startTime {
        let actualOffset = currentAdvice.vertrek.actualDate.timeIntervalSince1970
        let startOffset = startTime.timeIntervalSince1970
        let currentOffset = NSDate().timeIntervalSince1970

        let offsetForPercentage = min(1, max(0, 1 - ((currentOffset - actualOffset) / (startOffset - actualOffset))))

        leftBackgroundOffset = (backgroundView.bounds.width - view.bounds.width) * CGFloat(offsetForPercentage)
      } else {
        leftBackgroundOffset = 0
      }

      UIView.animateWithDuration(AnimationInterval) { [weak self] in
        self?.backgroundView.transform = CGAffineTransformMakeTranslation(-leftBackgroundOffset, 0)
      }

      let timeBeforeColonString: String
      let timeAfterColonString: String
      if difference.hour() > 0 {
        timeBeforeColonString = difference.toString(format: .Custom("H"))
        timeAfterColonString = difference.toString(format: .Custom("mm"))

      } else {
        timeBeforeColonString = difference.toString(format: .Custom("mm"))
        timeAfterColonString = difference.toString(format: .Custom("ss"))
      }

      timerMinutesLabel.text = timeBeforeColonString
      timerSecondsLabel.text = timeAfterColonString
    } else {
      timerMinutesLabel.text = "0"
      timerSecondsLabel.text = "00"
      platformLabel.text = ""
      aankomstVertraging.text = ""
      statusMessageLabel.text = ""
      extraLabel.text = ""
      stepsLabel.text = ""
    }

    if let nextAdvice = nextAdvice {

      let offset = nextAdvice.vertrek.actualDate.timeIntervalSinceDate(NSDate())
      let difference = NSDate(timeIntervalSince1970: offset - 60*60)

      let timeString: String
      if difference.hour() > 0 {
        timeString = difference.toString(format: .Custom("H:mm"))

      } else {
        timeString = difference.toString(format: .Custom("mm:ss"))
      }

      nextLabel.text = "\(timeString)" + (nextAdvice.vertrekSpoor.map { " - spoor \($0)" } ?? "") //+ " - \(nextAdvice.smallExtraMessage)"
      nextDelayLabel.text = nextAdvice.vertrekVertraging
      nextView.alpha = 1
    } else {
      nextView.alpha = 0
      nextDelayLabel.text = ""
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

  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Portrait
  }

}

