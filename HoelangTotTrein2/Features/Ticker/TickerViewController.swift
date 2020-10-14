//
//  ViewController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import Bindable
import API
import Core

class TickerViewController: UIViewController {

  private let AnimationInterval: TimeInterval = 2

  private var fromStation: Station?
  private var toStation: Station?
  private var currentAdvice: LoadingState<Advice?> = .loading { didSet { applyLoadedState() } }
  private var currentAdvices: LoadingState<AdvicesAndRequest> = .loading { didSet { applyLoadedState() } }

//  private var nextAdvice: Advice?

  private var startTime: Date?

  @IBOutlet private weak var backgroundView: UIImageView!
  @IBOutlet fileprivate weak var stackIndicatorView: UIStackView!

  @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

  @IBOutlet private weak var fromButton: UIButton!
  @IBOutlet private weak var toButton: UIButton!
  @IBOutlet private weak var fromIndicatorLabel: UILabel!
  @IBOutlet private weak var toIndicatorLabel: UILabel!

  @IBOutlet private weak var collectionView: UICollectionView!
  private var dataSource: TickerDataSource?

  //next
  @IBOutlet private weak var nextLabel: UILabel!
  @IBOutlet private weak var nextView: UIView!
  @IBOutlet private weak var nextViewBlur: UIVisualEffectView!
  @IBOutlet private weak var nextDelayLabel: UILabel!

  private var renderBackgroundToken: HeartBeat.Token?

  private let viewModel = ListTickerViewModel(travelService: App.travelService)

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource = TickerDataSource(advices: [], collectionView: collectionView)

    fromIndicatorLabel.text = R.string.localization.fromStation()
    toIndicatorLabel.text = R.string.localization.toStation()

    viewModel.fromButtonTitle.subscribe { [fromButton] variable in
      fromButton?.setTitle(variable.value, for: .normal)
    }.disposed(by: disposeBag)
    fromButton.setTitle(viewModel.fromButtonTitle.value, for: .normal)

    viewModel.toButtonTitle.subscribe { [toButton] variable in
      toButton?.setTitle(variable.value, for: .normal)
    }.disposed(by: disposeBag)
    toButton.setTitle(viewModel.fromButtonTitle.value, for: .normal)

    bind(\.currentAdvice, to: viewModel.currentAdvice)
    bind(\.currentAdvices, to: viewModel.currentAdvices)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    updateTickerView(0, current: nil, advices: [])

    collectionView.backgroundView = UIView()
    collectionView.backgroundColor = UIColor.clear

//    App.travelService.currentAdvicesObservable
//      .observeOn(MainScheduler.asyncInstance)
    
//      .distinctUntilChanged { (lhs, rhs) in
//        switch (lhs, rhs) {
//        case (.loading, .loading):
//          return true
//        case (.loaded(let lhsValue), .loaded(let rhsValue)):
//          return lhsValue == rhsValue
//        case (.loading, _):
//          return false
//        case (.loaded, _):
//          return false
//        }
//      }
//      .subscribe(onNext: { [weak self] advicesLoading in
//        guard let controller = self else {
//          return
//        }
//
//        let advices: Advices
//        switch (advicesLoading) {
//        case .loaded(let ad):
//          self?.activityIndicator.stopAnimating()
//          advices = ad
//        case .loading:
//          self?.activityIndicator.startAnimating()
//          advices = []
//        }
//
//        controller.dataSource?.advices = advices
//
//        DispatchQueue.main.async { [weak self] in
//          _ = self?.notifyCurrentAdvice()
//        }
//
//        _ = App.travelService.currentAdviceObservable
//          .take(1)
//          .subscribe(onNext: { [weak self] advice in
//            guard let advice = advice else { return }
//            self?.scrollToPersistedAdvice(advices, currentAdviceIdentifier: advice.identifier())
//            self?.updateCurrentAdviceOnScreen(forAdvice: advice, in: advices)
//          })
//      })
//      .disposed(by: bag)

//    App.travelService.currentAdviceObservable
//      .observeOn(MainScheduler.asyncInstance)
//      .subscribe(onNext:  { [weak self] advice in
//        guard let advice = advice else {
//          return
//        }
//        assert(Thread.isMainThread)
//        self?.currentAdvice = advice
//      })
//      .disposed(by: bag)
//
//    App.travelService.currentAdviceObservable
//      .distinctUntilChanged { $0 == $1 }
//      .observeOn(MainScheduler.asyncInstance)
//      .subscribe(onNext:  { [weak self] _ in
//        assert(Thread.isMainThread)
//        self?.startTime = Date()
//        self?.renderBackground()
//      })
//      .disposed(by: bag)
//
//    App.travelService.nextAdviceObservable.asObservable()
//      .observeOn(MainScheduler.asyncInstance)
//      .subscribe(onNext: { [weak self] advice in
//        self?.nextAdvice = advice
//      })
//      .disposed(by: bag)





//    App.travelService.firstAdviceRequestObservable
//      .observeOn(MainScheduler.asyncInstance)
//      .subscribe(onNext: { [weak self] adviceRequest in
//        guard let adviceRequest = adviceRequest else {
//          return
//        }
//        self?.fromStation = adviceRequest.from
//        self?.toStation = adviceRequest.to
////        self?.fromButton.setTitle(adviceRequest.from?.name ?? R.string.localization.select(), for: .normal)
////        self?.toButton.setTitle(adviceRequest.to?.name ?? R.string.localization.select(), for: .normal)
//      })
//      .disposed(by: bag)

//    collectionView.rx.didScroll
//      .subscribe(onNext: { [weak self] _ in
//        _ = self?.notifyCurrentAdvice()
//      })
//      .disposed(by: bag)

    renderBackgroundToken = App.heartBeat.register(type: .repeating(interval: 1), callback: { [weak self] _ in
      self?.renderBackground()
    })
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    renderBackgroundToken = nil
  }

  func showPickerController(_ state: PickerState) {

//    segueManager.performSegue(withIdentifier: R.segue.tickerViewController.presentPickerSegue.identifier) { [weak self] segue in
//
//      guard let controller = segue.destination as? PickerViewController else {
//        return
//      }
//
//      controller.state = state
//      controller.selectedStation = state == .from ? self?.fromStation : self?.toStation
//      controller.successHandler = { [weak controller] station in
//        App.travelService.setStation(state, byPicker: true, uicCode: station.UICCode)
//        controller?.dismiss(animated: true, completion: nil)
//      }
//
//      controller.cancelHandler = { [weak controller] in
//        controller?.dismiss(animated: true, completion: nil)
//      }
//    }
  }

  private func renderBackground() {
    if let currentAdvice = currentAdvice.value.flatMap({ $0 }) {
      let offset = currentAdvice.departure.actual.timeIntervalSince(Date())

      let leftBackgroundOffset: CGFloat
      if let startTime = startTime {
        let actualOffset = currentAdvice.departure.actual.timeIntervalSince1970
        let startOffset = startTime.timeIntervalSince1970
        let currentOffset = Date().timeIntervalSince1970

        let offsetForPercentage = min(1, max(0, 1 - ((currentOffset - actualOffset) / (startOffset - actualOffset))))

        leftBackgroundOffset = (backgroundView.bounds.width - view.bounds.width) * CGFloat(offsetForPercentage)
      } else {
        leftBackgroundOffset = 0
      }

//      UIView.animate(withDuration: AnimationInterval) { [weak self] in
//        self?.backgroundView.transform = CGAffineTransform(translationX: -leftBackgroundOffset/2, y: 0)
//      }
    }
  }

  private func applyLoadedState() {

    switch currentAdvices {
    case .loading:
      activityIndicator.startAnimating()
    case .error, .result:
      activityIndicator.stopAnimating()
    }

    dataSource?.advices = currentAdvices.value?.advices ?? []

    DispatchQueue.main.async { [weak self] in
      _ = self?.notifyCurrentAdvice()
    }

//    _ = App.travelService.currentAdviceObservable
//      .take(1)
//      .subscribe(onNext: { [weak self] advice in
//        guard let advice = advice else { return }
//        self?.scrollToPersistedAdvice(advices, currentAdviceIdentifier: advice.identifier())
//        self?.updateCurrentAdviceOnScreen(forAdvice: advice, in: advices)
//      })
  }

  private func applyErrorState() {

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
    .trap {
      print("ERROR: \($0)")
    }
  }

  @IBAction func switchPressed(_ sender: AnyObject) {
    App.travelService.switchFromTo()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }

  fileprivate func scrollToPersistedAdvice(_ advices: Advices, currentAdviceIdentifier: AdviceIdentifier) {
    let adviceAndIndexOpt = advices.enumerated().lazy
      .first{ $0.element.identifier == currentAdviceIdentifier }
    guard let adviceAndIndex = adviceAndIndexOpt else {
      return
    }

    collectionView.scrollToItem(at: IndexPath(row: adviceAndIndex.offset, section: 0), at: .top, animated: false)
  }

  private func notifyCurrentAdvice() -> Advice? {

    let center = view.convert(view.center, to: collectionView)
    guard let indexPath = collectionView.indexPathForItem(at: center),
      let advice = (collectionView.cellForItem(at: indexPath) as? AdviceCell)?.advice
      else {
      return nil
    }

    // TODO: Implement

//    if _currentAdvice == advice {
//      return advice
//    }
//
//    _currentAdvice = advice

//    _ = App.travelService.currentAdvicesObservable
//      .take(1)
//      .map { $0.value }
//      .filterOptional()
//      .subscribe(onNext: { [weak self] advices in
//        self?.updateCurrentAdviceOnScreen(forAdvice: advice, in: advices)
//      })

    return advice
  }

  private func updateCurrentAdviceOnScreen(forAdvice advice: Advice?, in advices: Advices) {
    let index = advices.enumerated().first { $0.element == advice }
    App.travelService.setCurrentAdviceOnScreen(advice: advice)
    updateTickerView(index?.offset ?? 0, current: advice, advices: advices)
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

  fileprivate func updateTickerView(_ i: Int, current: Advice?, advices: Advices) {
    assert(Thread.isMainThread, "call from main thread")
    let showAdvices = advices.prefix(6)

    stackIndicatorView.arrangedSubviews.forEach { $0.removeFromSuperview() }

    showAdvices.enumerated().forEach { (idx, element) in
      let view = createIndicatorView()
      stackIndicatorView.addArrangedSubview(view)

      view.isHidden = false

      let bgColor: UIColor
      if idx == i && !element.isOngoing && element == current {
        bgColor = UIColor.white.withAlphaComponent(0.2)
      } else if idx == i && (element.status != .NORMAL || element.vertrekVertraging != nil) {
        bgColor = UIColor.redTintColor()
      } else if idx == i {
        bgColor = UIColor.white
      } else if element.status != .NORMAL || element.vertrekVertraging != nil {
        bgColor = UIColor.redTintColor().withAlphaComponent(0.3)
      } else {
        bgColor = UIColor.clear
      }

      view.backgroundColor = bgColor
    }

  }
}
