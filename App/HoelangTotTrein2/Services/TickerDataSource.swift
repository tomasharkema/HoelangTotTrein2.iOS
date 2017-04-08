//
//  TickerDataSource.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 09-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import HoelangTotTreinAPI

class TickerFlowLayout: UICollectionViewFlowLayout {
  override init() {
    super.init()
    initialize()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  func initialize() {
    minimumLineSpacing = 0
    minimumInteritemSpacing = 0
  }
}

class TickerDataSource: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  var advices: Advices {
    didSet {
      assert(Thread.isMainThread)
      collectionView?.reloadData()
    }
  }
  
  fileprivate weak var collectionView: UICollectionView?
  fileprivate var disposable: Disposable?

  init(advices: Advices, collectionView: UICollectionView) {
    self.advices = advices
    self.collectionView = collectionView
    super.init()

    collectionView.register(R.nib.adviceCell)
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.reloadData()
  }

  deinit {
    disposable?.dispose()
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return advices.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.adviceCell, for: indexPath)!

    cell.advice = advices[indexPath.row]

    cell.renderTimer()

    return cell
  }

  func tick() {
    collectionView?.visibleCells.forEach {
      guard let adviceCell = $0 as? AdviceCell else {
        return
      }

      adviceCell.renderTimer()
    }
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return collectionView.frame.size
  }
}

