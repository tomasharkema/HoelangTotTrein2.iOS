//
//  ViewController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import SegueManager


class TickerViewController: ViewController {

  var fromStation: Station?
  var toStation: Station?

  @IBOutlet weak var fromButton: UIButton!
  @IBOutlet weak var toButton: UIButton!

  var currentAdviceSubscription: ObservableSubject<Advice>?
  var currentAdviceRequestSubscription: ObservableSubject<AdviceRequest>?

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    App.travelService.startTimer()
    currentAdviceSubscription = App.travelService.currentAdviceObservable.subscribe { advice in
      print(advice)
    }
    currentAdviceRequestSubscription = App.travelService.currentAdviceRequest.subscribe { [weak self] adviceRequest in
      print(adviceRequest)
      self?.fromStation = adviceRequest.from
      self?.toStation = adviceRequest.to
      self?.fromButton.setTitle(adviceRequest.from?.name ?? NSLocalizedString("[Selecteer]", comment: "selecteer"), forState: UIControlState.Normal)
      self?.toButton.setTitle(adviceRequest.to?.name ?? NSLocalizedString("[Selecteer]", comment: "selecteer"), forState: UIControlState.Normal)
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    App.travelService.stopTimer()
    if let currentAdviceSubscription = currentAdviceSubscription {
      App.travelService.currentAdviceObservable.unsubscribe(currentAdviceSubscription)
    }
    if let currentAdviceRequestSubscription = currentAdviceRequestSubscription {
      App.travelService.currentAdviceRequest.unsubscribe(currentAdviceRequestSubscription)
    }
  }

  func showPickerController(state: PickerState) {
    let controller = R.storyboard.main.pickerViewController!
    controller.state = state
    controller.selectedStation = state == .From ? fromStation : toStation

    controller.successHandler = { station in
      App.travelService.setStation(state, station: station)
      controller.dismissViewControllerAnimated(true, completion: nil)
    }

    controller.cancelHandler = {
      controller.dismissViewControllerAnimated(true, completion: nil)
    }

    presentViewController(controller, animated: true, completion: nil)
  }

  @IBAction func fromButtonPressed(sender: AnyObject) {
    showPickerController(.From)
  }

  @IBAction func toButtonPressed(sender: AnyObject) {
    showPickerController(.To)
  }
}

