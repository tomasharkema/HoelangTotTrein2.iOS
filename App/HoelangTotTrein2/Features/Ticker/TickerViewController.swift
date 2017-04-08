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
import HoelangTotTreinAPI

class TickerViewController: ViewController {

  private let AnimationInterval: TimeInterval = 0.5

  private var fromStation: Station?
  private var toStation: Station?

  private let disposeBag = DisposeBag()
  private var onScreenAdviceDisposable: Disposable?

  private var timer: Timer?
  private var currentAdvice: Advice?

  private var nextAdvice: Advice?

  private var startTime: Date?

  @IBOutlet private weak var backgroundView: UIImageView!
  @IBOutlet fileprivate weak var stackIndicatorView: UIStackView!

  @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

  @IBOutlet private weak var fromButton: UIButton!
  @IBOutlet private weak var fromLabel: UILabel!
  @IBOutlet private weak var toButton: UIButton!
  @IBOutlet private weak var toLabel: UILabel!
  @IBOutlet private weak var fromIndicatorLabel: UILabel!
  @IBOutlet private weak var toIndicatorLabel: UILabel!

  @IBOutlet private weak var collectionView: UICollectionView!
  private var dataSource: TickerDataSource?

  //next
  @IBOutlet private weak var nextLabel: UILabel!
  @IBOutlet private weak var nextView: UIView!
  @IBOutlet private weak var nextViewBlur: UIVisualEffectView!
  @IBOutlet private weak var nextDelayLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource = TickerDataSource(advices: [], collectionView: collectionView)

    fromIndicatorLabel.text = R.string.localization.fromStation()
    toIndicatorLabel.text = R.string.localization.toStation()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    startTimer()

    updateTickerView(0, advices: [])

    collectionView.backgroundView = UIView()
    collectionView.backgroundColor = UIColor.clear

    App.travelService.startTimer()
    NotificationCenter.default.addObserver(self, selector: #selector(startTimer), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(stopTimer), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

    App.travelService.currentAdvicesObservable.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] advicesLoading in
        guard let controller = self else {
          return
        }

        let advices: Advices
        switch (advicesLoading) {
        case .loaded(let ad):
          self?.activityIndicator.stopAnimating()
          advices = ad
        case .loading:
          self?.activityIndicator.startAnimating()
          advices = []
        }

        controller.dataSource?.advices = advices

        DispatchQueue.main.async { [weak self] in
          self?.notifyCurrentAdvice()
        }

        let advice = self?.scrollToPersistedAdvice(advices)
        self?.updateCurrentAdviceOnScreen(forAdvice: advice, in: advices)
      }).addDisposableTo(disposeBag)

    App.travelService.currentAdviceObservable.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext:  { [weak self] advice in
        guard let advice = advice else {
          return
        }
        self?.startTime = Date()
        self?.currentAdvice = advice
        self?.render()
      }).addDisposableTo(disposeBag)

    App.travelService.nextAdviceObservable.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] advice in
        self?.nextAdvice = advice
        self?.render()
      }).addDisposableTo(disposeBag)

    App.travelService.firstAdviceRequestObservable
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] adviceRequest in
        guard let adviceRequest = adviceRequest else {
          return
        }
        self?.fromStation = adviceRequest.from
        self?.toStation = adviceRequest.to
        self?.fromLabel.text = adviceRequest.from?.name ?? R.string.localization.select()
        self?.toLabel.text = adviceRequest.to?.name ?? NSLocalizedString("[Select]", comment: "selecteer")
      }).addDisposableTo(disposeBag)

    collectionView.rx.didScroll
      .subscribe(onNext: { [weak self] _ in
        _ = self?.notifyCurrentAdvice()
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

  private var _currentAdvice: Advice? = nil
  private func notifyCurrentAdvice() -> Advice? {

    let center = view.convert(view.center, to: collectionView)
    guard let indexPath = collectionView.indexPathForItem(at: center), let advice = (collectionView.cellForItem(at: indexPath) as? AdviceCell)?.advice else {
      return nil
    }

    if _currentAdvice == advice {
      return advice
    }

    _currentAdvice = advice

    UserDefaults.currentAdviceHash = advice.hashValue
    _ = App.travelService.currentAdvicesObservable
      .single()
      .map { $0.value }
      .filterOptional()
      .subscribe(onNext: { [weak self] advices in
        self?.updateCurrentAdviceOnScreen(forAdvice: advice, in: advices)
      })

    return advice
  }

  private func updateCurrentAdviceOnScreen(forAdvice advice: Advice?, in advices: Advices) {
    let index = advices.enumerated().filter { $0.element == advice }.first
    App.travelService.setCurrentAdviceOnScreen(advice: index?.element)
    updateTickerView(index?.offset ?? 0, advices: advices)
  }
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
      if idx == i && !element.isOngoing && element.hashValue == UserDefaults.currentAdviceHash {
        bgColor = UIColor.white.withAlphaComponent(0.2)
      } else if idx == i && (element.status != .VolgensPlan || element.vertrekVertraging != nil) {
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

