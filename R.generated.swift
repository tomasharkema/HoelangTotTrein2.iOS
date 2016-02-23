// This is a generated file, do not edit!
// Generated by R.swift, see https://github.com/mac-cain13/R.swift

import Foundation
import Rswift
import UIKit

struct R: Rswift.Validatable {
  static func validate() throws {
    try intern.validate()
  }
  
  struct file {
    static let bgPng = FileResource(bundle: _R.hostingBundle, name: "bg", pathExtension: "png")
    static let denHaagHSGpx = FileResource(bundle: _R.hostingBundle, name: "Den Haag HS", pathExtension: "gpx")
    static let hoofddorpGpx = FileResource(bundle: _R.hostingBundle, name: "Hoofddorp", pathExtension: "gpx")
    static let koogAanDeZaanGpx = FileResource(bundle: _R.hostingBundle, name: "Koog aan de Zaan", pathExtension: "gpx")
    static let nOIGpx = FileResource(bundle: _R.hostingBundle, name: "NOI", pathExtension: "gpx")
    static let sloterdijkGpx = FileResource(bundle: _R.hostingBundle, name: "sloterdijk", pathExtension: "gpx")
    static let zaandamGpx = FileResource(bundle: _R.hostingBundle, name: "Zaandam", pathExtension: "gpx")
    
    static func bgPng(_: Void) -> NSURL? {
      let fileResource = R.file.bgPng
      return fileResource.bundle?.URLForResource(fileResource)
    }
    
    static func bgPng(_: Void) -> String? {
      let fileResource = R.file.bgPng
      return fileResource.bundle?.pathForResource(fileResource)
    }
    
    static func denHaagHSGpx(_: Void) -> NSURL? {
      let fileResource = R.file.denHaagHSGpx
      return fileResource.bundle?.URLForResource(fileResource)
    }
    
    static func denHaagHSGpx(_: Void) -> String? {
      let fileResource = R.file.denHaagHSGpx
      return fileResource.bundle?.pathForResource(fileResource)
    }
    
    static func hoofddorpGpx(_: Void) -> NSURL? {
      let fileResource = R.file.hoofddorpGpx
      return fileResource.bundle?.URLForResource(fileResource)
    }
    
    static func hoofddorpGpx(_: Void) -> String? {
      let fileResource = R.file.hoofddorpGpx
      return fileResource.bundle?.pathForResource(fileResource)
    }
    
    static func koogAanDeZaanGpx(_: Void) -> NSURL? {
      let fileResource = R.file.koogAanDeZaanGpx
      return fileResource.bundle?.URLForResource(fileResource)
    }
    
    static func koogAanDeZaanGpx(_: Void) -> String? {
      let fileResource = R.file.koogAanDeZaanGpx
      return fileResource.bundle?.pathForResource(fileResource)
    }
    
    static func nOIGpx(_: Void) -> NSURL? {
      let fileResource = R.file.nOIGpx
      return fileResource.bundle?.URLForResource(fileResource)
    }
    
    static func nOIGpx(_: Void) -> String? {
      let fileResource = R.file.nOIGpx
      return fileResource.bundle?.pathForResource(fileResource)
    }
    
    static func sloterdijkGpx(_: Void) -> NSURL? {
      let fileResource = R.file.sloterdijkGpx
      return fileResource.bundle?.URLForResource(fileResource)
    }
    
    static func sloterdijkGpx(_: Void) -> String? {
      let fileResource = R.file.sloterdijkGpx
      return fileResource.bundle?.pathForResource(fileResource)
    }
    
    static func zaandamGpx(_: Void) -> NSURL? {
      let fileResource = R.file.zaandamGpx
      return fileResource.bundle?.URLForResource(fileResource)
    }
    
    static func zaandamGpx(_: Void) -> String? {
      let fileResource = R.file.zaandamGpx
      return fileResource.bundle?.pathForResource(fileResource)
    }
  }
  
  struct font {
    
  }
  
  struct image {
    static let current_location = ImageResource(bundle: _R.hostingBundle, name: "current_location")
    static let settings = ImageResource(bundle: _R.hostingBundle, name: "settings")
    static let switch_from_to = ImageResource(bundle: _R.hostingBundle, name: "switch_from_to")
    
    static func current_location(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.current_location, compatibleWithTraitCollection: traitCollection)
    }
    
    static func settings(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.settings, compatibleWithTraitCollection: traitCollection)
    }
    
    static func switch_from_to(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.switch_from_to, compatibleWithTraitCollection: traitCollection)
    }
  }
  
  private struct intern: Rswift.Validatable {
    static func validate() throws {
      try _R.validate()
    }
  }
  
  struct nib {
    
  }
  
  struct reuseIdentifier {
    static let stationCell: ReuseIdentifier<StationCell> = ReuseIdentifier(identifier: "StationCell")
  }
  
  struct segue {
    struct tickerViewController {
      static let presentPickerSegue: StoryboardSegueIdentifier<UIStoryboardSegue, TickerViewController, PickerViewController> = StoryboardSegueIdentifier(identifier: "presentPickerSegue")
      
      static func presentPickerSegue(segue segue: UIStoryboardSegue) -> TypedStoryboardSegueInfo<UIStoryboardSegue, TickerViewController, PickerViewController>? {
        return TypedStoryboardSegueInfo(segueIdentifier: R.segue.tickerViewController.presentPickerSegue, segue: segue)
      }
    }
  }
  
  struct storyboard {
    static let launchScreen = _R.storyboard.launchScreen()
    static let main = _R.storyboard.main()
    
    static func launchScreen(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.launchScreen)
    }
    
    static func main(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.main)
    }
  }
}

struct _R: Rswift.Validatable {
  static let hostingBundle = NSBundle(identifier: "nl.tomasharkema.HoelangTotTrein")
  
  static func validate() throws {
    try storyboard.validate()
  }
  
  struct nib {
    
  }
  
  struct storyboard: Rswift.Validatable {
    static func validate() throws {
      try launchScreen.validate()
      try main.validate()
    }
    
    struct launchScreen: Rswift.Validatable, StoryboardResourceWithInitialControllerType {
      typealias InitialController = UIViewController
      
      let bundle = _R.hostingBundle
      let name = "LaunchScreen"
      
      static func validate() throws {
        if UIImage(named: "bg") == nil { throw ValidationError(description: "[R.swift] Image named 'bg' is used in storyboard 'LaunchScreen', but couldn't be loaded.") }
      }
    }
    
    struct main: Rswift.Validatable, StoryboardResourceWithInitialControllerType {
      typealias InitialController = TickerViewController
      
      let bundle = _R.hostingBundle
      let name = "Main"
      
      func pickerViewController() -> PickerViewController? {
        return UIStoryboard(resource: self).instantiateViewControllerWithIdentifier("PickerViewController") as? PickerViewController
      }
      
      static func validate() throws {
        if UIImage(named: "switch_from_to") == nil { throw ValidationError(description: "[R.swift] Image named 'switch_from_to' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIImage(named: "current_location") == nil { throw ValidationError(description: "[R.swift] Image named 'current_location' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIImage(named: "bg.png") == nil { throw ValidationError(description: "[R.swift] Image named 'bg.png' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIImage(named: "settings") == nil { throw ValidationError(description: "[R.swift] Image named 'settings' is used in storyboard 'Main', but couldn't be loaded.") }
        if _R.storyboard.main().pickerViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'pickerViewController' could not be loaded from storyboard 'Main' as 'PickerViewController'.") }
      }
    }
  }
}