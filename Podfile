# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'

source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

#link_with 'HLTT'

pod 'Alamofire', '~> 3.0'
pod 'Promissum', '~> 0.5'
pod 'Promissum/CoreDataKit', '~> 0.5'
pod 'Promissum/Alamofire', '~> 0.5'
pod 'Promissum/UIKit', '~> 0.5'
pod 'SegueManager/R.swift', '~> 1.2'
pod 'CoreDataKit'
pod 'AFDateHelper'
pod 'NewRelicAgent', '~> 5.4.0'

pod 'RxSwift',    '~> 2.0'
pod 'RxCocoa',    '~> 2.0'
pod 'RxBlocking', '~> 2.0'
#pod 'RxTests',    '~> 2.0'

pod 'R.swift'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
    end
  end
end
