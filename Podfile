# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'

source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

link_with 'HoelangTotTrein2'

pod 'Alamofire'
pod 'R.swift'
pod 'Promissum'
pod 'Promissum/CoreDataKit'
pod 'Promissum/Alamofire'
pod 'CoreDataKit'
pod 'SegueManager'
pod 'AFDateHelper'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
    end
  end
end
