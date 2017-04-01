//
//  ViewController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import SegueManager

class ViewController: UIViewController, SegueManagerController {

  var segueManager: SegueManager!

  override func viewDidLoad() {
    super.viewDidLoad()
    segueManager = SegueManager(viewController: self)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    segueManager.prepareForSegue(segue)
  }
}
