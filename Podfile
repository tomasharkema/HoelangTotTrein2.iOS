workspace 'HoelangTotTrein2.xcworkspace'

abstract_target 'HoelangTotTrein2Pods' do
	use_frameworks!
  	platform :ios, '10.0'

	pod 'Promissum'
	pod 'Promissum/Alamofire'
	pod 'Promissum/UIKit'

    pod 'Statham', :git => 'https://github.com/tomasharkema/Statham.git'
    pod 'Statham/Alamofire+Promissum', :git => 'https://github.com/tomasharkema/Statham.git'

	pod 'RxSwift',    '~> 3.0'
	pod 'RxCocoa',    '~> 3.0'

	target 'HoelangTotTrein2' do
		project 'App/HoelangTotTrein2.xcodeproj'

		pod 'HockeySDK'
		pod 'R.swift', '~> 3.2'
		pod 'SegueManager/R.swift', '~> 3.1.0'
		pod 'AFDateHelper', '~> 4.0'

		target 'HoelangTotTrein2Tests' do
			inherit! :search_paths
		end
		target 'Widget' do
			inherit! :search_paths
		end
  end

  target 'HoelangTotTreinAPI' do
    use_frameworks!
    platform :ios, '10.0'
    project 'API/HoelangTotTreinAPI.xcodeproj'

    target 'HoelangTotTreinAPITests' do
      inherit! :search_paths
    end
  end

  target 'HoelangTotTreinCore' do
    use_frameworks!
    platform :ios, '10.0'
    project 'Core/HoelangTotTreinCore.xcodeproj'

    target 'HoelangTotTreinCoreTests' do
      inherit! :search_paths
      pod 'RxTest', '~> 3.0'
    end
  end

end

abstract_target 'HoelangTotTrein2WatchPods' do
  use_frameworks!
  platform :watchos, '3.0'

  pod 'Statham', :git => 'https://github.com/tomasharkema/Statham.git'
	pod 'RxSwift',    '~> 3.0'

  target 'HLTT Extension' do
    project 'App/HoelangTotTrein2.xcodeproj'
  end

  target 'HoelangTotTreinAPIWatch' do
    project 'API/HoelangTotTreinAPI.xcodeproj'

    # pod 'Promissum/Alamofire', :git => "https://github.com/tomlokhorst/Promissum.git", :branch => "feature/deinit-warning-swift3"

    # pod 'Statham/Alamofire+Promissum', :git => 'https://github.com/tomasharkema/Statham.git'

    # target 'HoelangTotTreinAPITests' do
    # 	inherit! :search_paths
    # end
  end

    target 'HoelangTotTreinCoreWatch' do
	    project 'Core/HoelangTotTreinCore.xcodeproj'
	  end
end
