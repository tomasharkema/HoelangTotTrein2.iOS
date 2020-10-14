//
//  Ticker.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23/07/2019.
//  Copyright © 2019 Tomas Harkema. All rights reserved.
//

import SwiftUI
import UIKit

struct Ticker: View {
  var date: Date
  var fontSize: CGFloat = 100
  var textAlignment: NSTextAlignment = .center
  var fontWeight: UIFont.Weight = .light

  var body: some View {
    TickerView(date: .constant(self.date), fontSize: fontSize, textAlignment: textAlignment, fontWeight: fontWeight)
  }
}

struct TickerView: UIViewRepresentable {
  @Binding var date: Date
  var fontSize: CGFloat = 100
  var textAlignment: NSTextAlignment = .left
  let fontWeight: UIFont.Weight

  func makeUIView(context _: UIViewRepresentableContext<TickerView>) -> UITickerView {
    let label = UITickerView(frame: .zero)
    label.date = date
    label.start()
    label.fontSize = fontSize
    label.textAlignment = textAlignment
    label.setContentHuggingPriority(.required, for: .horizontal)
    label.setContentHuggingPriority(.required, for: .vertical)
    return label
  }

  func updateUIView(_ uiView: UITickerView, context _: UIViewRepresentableContext<TickerView>) {
    uiView.date = date
    uiView.fontSize = fontSize
  }

  static func dismantleUIView(_ uiView: UITickerView, coordinator _: ()) {
    uiView.stop()
  }
}

class UITickerView: UILabel {
  private let formatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.second, .minute, .hour]
    return formatter
  }()

  private var displaylink: CADisplayLink?
  var date = Date()
  var fontSize: CGFloat = 100 {
    didSet {
      update()
    }
  }

  var fontWeight: UIFont.Weight = .light {
    didSet {
      update()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initialize()
  }

  private func initialize() {
    update()
    step()
  }

  private func update() {
    font = UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: fontWeight)
    textColor = .white
    textAlignment = .center
    step()
  }

  func start() {
    displaylink = CADisplayLink(target: self, selector: #selector(step))
    displaylink?.preferredFramesPerSecond = 10
    displaylink?.add(to: .current, forMode: .default)
  }

  func stop() {
    displaylink?.invalidate()
    displaylink = nil
  }

  @objc func step() {
    let offset = date.timeIntervalSinceNow
    let text: String
    if offset > 0 {
      text = formatter.string(from: date.timeIntervalSinceNow) ?? "0"
    } else {
      text = "0"
    }
    self.text = text
    setNeedsLayout()
    layoutIfNeeded()
  }
}
