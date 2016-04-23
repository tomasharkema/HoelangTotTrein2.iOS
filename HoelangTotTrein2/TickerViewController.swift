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
import RxSwift

class TickerViewController: ViewController {

  let AnimationInterval: NSTimeInterval = 0.5

  var fromStation: Station?
  var toStation: Station?

  let disposeBag = DisposeBag()
  var onScreenAdviceDisposable: Disposable?

  var timer: NSTimer?
  var currentAdvice: Advice?

  var nextAdvice: Advice?

  var startTime: NSDate?

  @IBOutlet weak var backgroundView: UIImageView!
  @IBOutlet weak var stackIndicatorView: UIStackView!

  @IBOutlet weak var fromButton: UIButton!
  @IBOutlet weak var toButton: UIButton!

  @IBOutlet weak var collectionView: UICollectionView!
  var dataSource: TickerDataSource?

  //next
  @IBOutlet weak var nextLabel: UILabel!
  @IBOutlet weak var nextView: UIView!
  @IBOutlet weak var nextViewBlur: UIVisualEffectView!
  @IBOutlet weak var nextDelayLabel: UILabel!

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    startTimer()

    updateTickerView(0, advices: [])

    collectionView.backgroundView = UIView()
    collectionView.backgroundColor = UIColor.clearColor()

    App.travelService.startTimer()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(startTimer), name: UIApplicationDidBecomeActiveNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(stopTimer), name: UIApplicationDidEnterBackgroundNotification, object: nil)

    fromButton.clipsToBounds = false
    toButton.clipsToBounds = false
    fromButton.titleLabel?.bounds = fromButton.bounds
    toButton.titleLabel?.bounds = toButton.bounds

    App.travelService.currentAdvicesObservable.asObservable().subscribeNext { [weak self] advices in
      guard let advices = advices, service = self else {
        return
      }
      service.dataSource = TickerDataSource(advices: advices, collectionView: service.collectionView)
      service.onScreenAdviceDisposable?.dispose()
      service.onScreenAdviceDisposable = service.dataSource?.onScreenAdviceObservable
        .filter { $0 != nil }
        .subscribeNext { [weak self] advice in
          UserDefaults.currentAdviceHash = advice!.hashValue

          let index = advices.enumerate().filter { $0.element == advice }.first

          App.travelService.currentAdviceOnScreenVariable.value = index?.element
          self?.updateTickerView(index?.index ?? 0, advices: advices)
        }
    }.addDisposableTo(disposeBag)

    App.travelService.currentAdvicesObservable.asObservable()
      .delaySubscription(0.1, scheduler: MainScheduler.asyncInstance)
      .filter { $0 != nil }
      .subscribeNext { [weak self] in
        let advice = self?.scrollToPersistedAdvice($0!)
        let index = $0!.enumerate().filter { $0.element == advice }.first
        App.travelService.currentAdviceOnScreenVariable.value = index?.element
        self?.updateTickerView(index?.index ?? 0, advices: $0!)
      }.addDisposableTo(disposeBag)

    App.travelService.currentAdviceObservable.asObservable().subscribeNext { [weak self] advice in
      guard let advice = advice else {
        return
      }
      self?.startTime = NSDate()
      self?.currentAdvice = advice
      self?.render()
    }.addDisposableTo(disposeBag)

    App.travelService.nextAdviceObservable.asObservable().subscribeNext { [weak self] advice in
      self?.nextAdvice = advice
      self?.render()
    }.addDisposableTo(disposeBag)

    App.travelService.firstAdviceRequest.asObservable().subscribeNext { [weak self] adviceRequest in
      guard let adviceRequest = adviceRequest else {
        return
      }
      self?.fromStation = adviceRequest.from
      self?.toStation = adviceRequest.to
      self?.fromButton.setTitle(adviceRequest.from?.name ?? NSLocalizedString("[Select]", comment: "selecteer"), forState: UIControlState.Normal)
      self?.toButton.setTitle(adviceRequest.to?.name ?? NSLocalizedString("[Select]", comment: "selecteer"), forState: UIControlState.Normal)
    }.addDisposableTo(disposeBag)

    render()
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    stopTimer()
    NSNotificationCenter.defaultCenter().removeObserver(self)

    App.travelService.stopTimer()
  }

  func startTimer() {
    if timer == nil {
      timer = NSTimer.scheduledTimerWithTimeInterval(AnimationInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
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
    dataSource?.tick()
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
        self?.backgroundView.transform = CGAffineTransformMakeTranslation(-leftBackgroundOffset/2, 0)
      }
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

  func applyErrorState() {

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

  private func scrollToPersistedAdvice(advices: Advices) -> Advice? {

    let persistedHash = UserDefaults.currentAdviceHash

    let adviceAndIndexOpt = advices.enumerate().lazy.filter { $0.element.hashValue == persistedHash }.first
    guard let adviceAndIndex = adviceAndIndexOpt else {
      return nil
    }

    collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: adviceAndIndex.index, inSection: 0), atScrollPosition: .Top, animated: false)
    return adviceAndIndex.element
  }

  private var _indicatorStackViewCache = [Int: UIView]()
}

extension TickerViewController {

  private func createIndicatorView() -> UIView {
    let width: CGFloat = 15
    let height: CGFloat = width
    let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
    view.layer.cornerRadius = width/2
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.whiteColor().CGColor

    view.addConstraint(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: width))
    view.addConstraint(NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: height))
    return view
  }

  private func updateTickerView(i: Int, advices: Advices) {
    assert(NSThread.isMainThread(), "call from main thread")
    advices.enumerate().forEach { (idx, element) in

      let view: UIView
      if let cachedView = _indicatorStackViewCache[idx] {
        view = cachedView
      } else {
        let newView = createIndicatorView()
        self._indicatorStackViewCache[idx] = newView
        self.stackIndicatorView.addArrangedSubview(newView)
        view = newView
      }

      view.hidden = false

      let bgColor: UIColor
      if idx == i && (element.status != .VolgensPlan || element.vertrekVertraging != nil) {
        bgColor = UIColor.redTintColor()
      } else if idx == i {
        bgColor = UIColor.whiteColor()
      } else if (element.status != .VolgensPlan || element.vertrekVertraging != nil) {
        bgColor = UIColor.redTintColor().colorWithAlphaComponent(0.3)
      } else {
        bgColor = UIColor.clearColor()
      }

      view.backgroundColor = bgColor
    }

    stackIndicatorView.arrangedSubviews.skip(advices.count).forEach {
      $0.hidden = true
    }
  }
}

