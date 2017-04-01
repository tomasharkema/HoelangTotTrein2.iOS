
workspace 'HoelangTotTrein2.xcworkspace'
platform :ios, '10.0'

abstract_target 'HoelangTotTreinPods' do
	use_frameworks!

	pod 'R.swift', '~> 3.2'
	pod 'NewRelicAgent', '~> 5.4.0'
	# pod 'CoreDataKit', '~> 0.11.0'
  	pod 'Alamofire', '~> 4.4'

	pod 'Promissum', '~> 1.0'
	pod 'Promissum/Alamofire', '~> 1.0'
	pod 'Promissum/UIKit', '~> 1.0'
	# pod 'Promissum/CoreDataKit', '~> 1.0'
	
	pod 'SegueManager/R.swift', '~> 3.1.0'
	pod 'AFDateHelper', '~> 4.0'
	pod 'RxSwift',    '~> 3.0'
	pod 'RxCocoa',    '~> 3.0'
	pod 'RxBlocking', '~> 3.0'

	pod 'Statham', :git => 'https://github.com/tomasharkema/Statham.git'
  	pod 'Statham/Alamofire+Promissum', :git => 'https://github.com/tomasharkema/Statham.git'

  	target 'HoelangTotTrein2' do
    	project 'HoelangTotTrein2.xcodeproj'
  	end

 #  	target 'HLTT Extension' do
	# 	platform :watchos, '2.0'
	# end
end




# post_install do |installer|
#   installer.pods_project.targets.each do |target|
#     target.build_configurations.each do |config|
#       config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
#       config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
#       config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
#     end
#   end
# end
