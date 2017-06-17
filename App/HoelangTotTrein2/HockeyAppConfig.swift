import Foundation
import HockeySDK
class HockeyAppConfig {
  static func register() {
    // Register hockeyapp 
    #if RELEASE
    BITHockeyManager.shared().configure(withIdentifier: "fc931b7f3d924374a03c27e0aaa9afb0")
    BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
//    BITHockeyManager.shared().updateManager.isCheckForUpdateOnLaunch = true
    BITHockeyManager.shared().updateManager.alwaysShowUpdateReminder = false
    BITHockeyManager.shared().start()
    BITHockeyManager.shared().authenticator.authenticateInstallation()
    #endif
  }
}

