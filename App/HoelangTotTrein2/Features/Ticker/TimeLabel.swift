//
//  TimeLabel.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 07-06-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import HoelangTotTreinCore

class TimeLabel: UILabel {

  private let heartBeat = App.heartBeat
  var goNegative = false

  var formatter: DateComponentsFormatter!
  private(set) var secondsToNul: Int = 0

  private var displayLink: CADisplayLink!

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  deinit {
    isActive = false
  }

  private func initialize() {
    displayLink = CADisplayLink(target: self, selector: #selector(render))
    NotificationCenter.default.addObserver(self, selector: #selector(becomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(becomeInactive), name: UIApplication.willResignActiveNotification, object: nil)
  }

  var isActive: Bool = false {
    didSet {
      if isActive {
        displayLink.add(to: .main, forMode: .default)
      } else {
        displayLink.remove(from: .main, forMode: .default)
      }
    }
  }

  var date: Date? {
    didSet {
      render()
    }
  }

  @objc private func render() {
    guard let date = date else {
      return
    }

    secondsToNul = Calendar.current.dateComponents([.second], from: Date(), to: date).second ?? 0

    if secondsToNul < 0 {
      text = "0:00"
    } else {
      let format = formatter.string(from: Date(), to: date)
      if text != format {
        text = format
      }
    }
  }

  @objc private func becomeActive() {
    displayLink.isPaused = false
  }

  @objc private func becomeInactive() {
    displayLink.isPaused = true
  }
}
