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

  let AnimationInterval: TimeInterval = 0.5

  var fromStation: Station?
  var toStation: Station?

  let disposeBag = DisposeBag()
  var onScreenAdviceDisposable: Disposable?

  var timer: Timer?
  var currentAdvice: Advice?

  var nextAdvice: Advice?

  var startTime: Date?

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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    startTimer()

    updateTickerView(0, advices: [])

    collectionView.backgroundView = UIView()
    collectionView.backgroundColor = UIColor.clear

    App.travelService.startTimer()
    NotificationCenter.default.addObserver(self, selector: #selector(startTimer), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(stopTimer), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

    fromButton.clipsToBounds = false
    toButton.clipsToBounds = false
    fromButton.titleLabel?.bounds = fromButton.bounds
    toButton.titleLabel?.bounds = toButton.bounds

    App.travelService.currentAdvicesObservable.asObservable().subscribe(onNext: { [weak self] advices in
      guard let advices = advices, let service = self else {
        return
      }
      service.dataSource = TickerDataSource(advices: advices, collectionView: service.collectionView)
      service.onScreenAdviceDisposable?.dispose()
      service.onScreenAdviceDisposable = service.dataSource?.onScreenAdviceObservable
        .filter { $0 != nil }
        .subscribe(onNext: { [weak self] advice in
          UserDefaults.currentAdviceHash = advice!.hashValue

          let index = advices.enumerated().filter { $0.element == advice }.first

          App.travelService.currentAdviceOnScreenVariable.value = index?.element
          self?.updateTickerView(index?.offset ?? 0, advices: advices)
        })
    }).addDisposableTo(disposeBag)

    App.travelService.currentAdvicesObservable.asObservable()
      .delaySubscription(0.1, scheduler: MainScheduler.asyncInstance)
      .filter { $0 != nil }
      .subscribe(onNext: { [weak self] in
        let advice = self?.scrollToPersistedAdvice($0!)
        let index = $0!.enumerated().filter { $0.element == advice }.first
        App.travelService.currentAdviceOnScreenVariable.value = index?.element
        self?.updateTickerView(index?.offset ?? 0, advices: $0!)
      }).addDisposableTo(disposeBag)

    App.travelService.currentAdviceObservable.asObservable().subscribe(onNext:  { [weak self] advice in
      guard let advice = advice else {
        return
      }
      self?.startTime = Date()
      self?.currentAdvice = advice
      self?.render()
    }).addDisposableTo(disposeBag)

    App.travelService.nextAdviceObservable.asObservable().subscribe(onNext: { [weak self] advice in
      self?.nextAdvice = advice
      self?.render()
    }).addDisposableTo(disposeBag)

    App.travelService.firstAdviceRequest.asObservable().subscribe(onNext: { [weak self] adviceRequest in
      guard let adviceRequest = adviceRequest else {
        return
      }
      self?.fromStation = adviceRequest.from
      self?.toStation = adviceRequest.to
      self?.fromButton.setTitle(adviceRequest.from?.name ?? NSLocalizedString("[Select]", comment: "selecteer"), for: .normal)
      self?.toButton.setTitle(adviceRequest.to?.name ?? NSLocalizedString("[Select]", comment: "selecteer"), for: .normal)
    }).addDisposableTo(disposeBag)

    render()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    stopTimer()
    NotificationCenter.default.removeObserver(self)

    App.travelService.stopTimer()
  }

  func startTimer() {
    if timer == nil {
      timer = Timer.scheduledTimer(timeInterval: AnimationInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  func showPickerController(_ state: PickerState) {

    segueManager.performSegue(withIdentifier: R.segue.tickerViewController.presentPickerSegue.identifier) { [weak self] segue in

      let controller = segue.destination as! PickerViewController

      controller.state = state
      controller.selectedStation = state == .from ? self?.fromStation : self?.toStation
      controller.successHandler = { [weak controller] station in
        App.travelService.setStation(state, station: station, byPicker: true)
          .then {
            print($0)
          }
          .trap {
            print($0)
          }
        controller?.dismiss(animated: true, completion: nil)
      }

      controller.cancelHandler = { [weak controller] in
        controller?.dismiss(animated: true, completion: nil)
      }
    }
  }

  func tick(_ timer: Timer) {
    render()
    dataSource?.tick()
  }

  func render() {
    if let currentAdvice = currentAdvice {
      let offset = currentAdvice.vertrek.actualDate.timeIntervalSince(Date())
      let difference = Date(timeIntervalSince1970: offset - 60*60)

      let leftBackgroundOffset: CGFloat
      if let startTime = startTime {
        let actualOffset = currentAdvice.vertrek.actualDate.timeIntervalSince1970
        let startOffset = startTime.timeIntervalSince1970
        let currentOffset = Date().timeIntervalSince1970

        let offsetForPercentage = min(1, max(0, 1 - ((currentOffset - actualOffset) / (startOffset - actualOffset))))

        leftBackgroundOffset = (backgroundView.bounds.width - view.bounds.width) * CGFloat(offsetForPercentage)
      } else {
        leftBackgroundOffset = 0
      }

      UIView.animate(withDuration: AnimationInterval, animations: { [weak self] in
        self?.backgroundView.transform = CGAffineTransform(translationX: -leftBackgroundOffset/2, y: 0)
      }) 
    }

    if let nextAdvice = nextAdvice {

      let offset = nextAdvice.vertrek.actualDate.timeIntervalSince(Date())
      let difference = Date(timeIntervalSince1970: offset - 60*60)

      let timeString: String
      if Calendar.current.component(.hour, from: difference) > 0 {
        timeString = difference.toString(format: .custom("H:mm"))

      } else {
        timeString = difference.toString(format: .custom("mm:ss"))
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

  @IBAction func fromButtonPressed(_ sender: AnyObject) {
    showPickerController(.from)
  }

  @IBAction func toButtonPressed(_ sender: AnyObject) {
    showPickerController(.to)
  }

  @IBAction func currentLocationPressed(_ sender: AnyObject) {
    App.locationService.requestAuthorization().flatMap { state in
      App.travelService.travelFromCurrentLocation()
    }.then { print($0) }
  }

  @IBAction func switchPressed(_ sender: AnyObject) {
    App.travelService.switchFromTo().then { print($0) }
  }

  override var preferredStatusBarStyle : UIStatusBarStyle {
    return .lightContent
  }

  override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
    return .portrait
  }

  fileprivate func scrollToPersistedAdvice(_ advices: Advices) -> Advice? {

    let persistedHash = UserDefaults.currentAdviceHash

    let adviceAndIndexOpt = advices.enumerated().lazy
      .first{ $0.element.hashValue == persistedHash }
    guard let adviceAndIndex = adviceAndIndexOpt else {
      return nil
    }

    collectionView.scrollToItem(at: IndexPath(row: adviceAndIndex.offset, section: 0), at: .top, animated: false)
    return adviceAndIndex.element
  }

  fileprivate var _indicatorStackViewCache = [Int: UIView]()
}

extension TickerViewController {

  fileprivate func createIndicatorView() -> UIView {
    let width: CGFloat = 15
    let height: CGFloat = width
    let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
    view.layer.cornerRadius = width/2
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.white.cgColor

    view.addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
    view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height))
    return view
  }

  fileprivate func updateTickerView(_ i: Int, advices: Advices) {
    assert(Thread.isMainThread, "call from main thread")
    advices.enumerated().forEach { (idx, element) in

      let view: UIView
      if let cachedView = _indicatorStackViewCache[idx] {
        view = cachedView
      } else {
        let newView = createIndicatorView()
        self._indicatorStackViewCache[idx] = newView
        self.stackIndicatorView.addArrangedSubview(newView)
        view = newView
      }

      view.isHidden = false

      let bgColor: UIColor
      if idx == i && (element.status != .VolgensPlan || element.vertrekVertraging != nil) {
        bgColor = UIColor.redTintColor()
      } else if idx == i {
        bgColor = UIColor.white
      } else if (element.status != .VolgensPlan || element.vertrekVertraging != nil) {
        bgColor = UIColor.redTintColor().withAlphaComponent(0.3)
      } else {
        bgColor = UIColor.clear
      }

      view.backgroundColor = bgColor
    }

    stackIndicatorView.arrangedSubviews.skip(advices.count).forEach {
      $0.isHidden = true
    }
  }
}

