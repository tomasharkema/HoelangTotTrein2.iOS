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
    itemSize = UIScreen.mainScreen().bounds.size
  }

}

class TickerDataSource: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  private let advices: Advices
  private weak var collectionView: UICollectionView?
  private var disposable: Disposable?

  private let didDecellerateObservable = Variable(0)
  private(set) var onScreenAdviceObservable: Observable<Advice?>!

  init(advices: Advices, collectionView: UICollectionView) {
    self.advices = advices
    self.collectionView = collectionView
    super.init()
    collectionView.registerNib(R.nib.adviceCell)
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.reloadData()

    onScreenAdviceObservable = didDecellerateObservable.asObservable()
      .filter { $0 == 1 }
      .debounce(0.5, scheduler: MainScheduler.asyncInstance)
      .map { [weak self] (el: Int) -> Advice? in
        guard let cv = self?.collectionView else {
          return nil
        }

        let sortedCells = cv.indexPathsForVisibleItems()
          .flatMap {
            cv.layoutAttributesForItemAtIndexPath($0)
          }
          .map {
            (cv.convertPoint($0.center, toView: cv.superview), $0)
          }
          .sort {
            let l = abs($0.0.0.y - (UIScreen.mainScreen().bounds.height/2))
            let r = abs($0.1.0.y - (UIScreen.mainScreen().bounds.height/2))
            return l < r
          }

        let cells = sortedCells.lazy.map { (center: CGPoint, el: UICollectionViewLayoutAttributes) in
          cv.cellForItemAtIndexPath(el.indexPath)
        }

        guard let advice = (cells.first as? AdviceCell)?.advice else {
          return nil
        }
        return advice
      }.asObservable()

  }

  deinit {
    disposable?.dispose()
  }

  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return advices.count
  }

  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(R.reuseIdentifier.adviceCell, forIndexPath: indexPath)!

    cell.advice = advices[indexPath.row]

    return cell
  }

  func tick() {
    collectionView?.visibleCells().forEach {
      guard let adviceCell = $0 as? AdviceCell else {
        return
      }

      adviceCell.renderTimer()
    }
  }

  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    didDecellerateObservable.value = 1
  }
}

