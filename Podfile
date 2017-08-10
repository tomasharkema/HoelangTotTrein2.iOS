workspace 'HoelangTotTrein2.xcworkspace'

abstract_target 'HoelangTotTrein2Pods' do
	use_frameworks!
  platform :ios, '10.0'

	pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :branch => "swift4"

	pod 'Promissum', :git => 'https://github.com/tomasharkema/Promissum.git', :commit => 'ff41d41ce367422e2d5c38c8d3115f815efb7970'
	pod 'Promissum/Alamofire', :git => 'https://github.com/tomasharkema/Promissum.git', :commit => 'ff41d41ce367422e2d5c38c8d3115f815efb7970'
	pod 'Promissum/UIKit', :git => 'https://github.com/tomasharkema/Promissum.git', :commit => 'ff41d41ce367422e2d5c38c8d3115f815efb7970'

  pod 'Statham', :git => 'https://github.com/tomasharkema/Statham.git', :commit => '698ffe0b57d4b7a46a8f48ad5ea8f927f63b0980'
  pod 'Statham/Alamofire+Promissum', :git => 'https://github.com/tomasharkema/Statham.git', :commit => '698ffe0b57d4b7a46a8f48ad5ea8f927f63b0980'

	pod 'RxSwift',    '~> 3.5'
	pod 'RxCocoa',    '~> 3.5'

	target 'HoelangTotTrein2' do
    use_frameworks!
    platform :ios, '10.0'
		project 'App/HoelangTotTrein2.xcodeproj'

		pod 'HockeySDK'
		pod 'R.swift', '~> 3.2'
		pod 'SegueManager/R.swift', '~> 3.1.0'
		pod 'AFDateHelper', '~> 4.0'
    pod 'Fabric'
    pod 'Crashlytics'

		target 'HoelangTotTrein2Tests' do
			inherit! :search_paths
		end
		target 'Widget' do
			inherit! :search_paths
		end
		target 'TickerNotification' do
			inherit! :search_paths
		end
  end

  target 'HoelangTotTreinAPI' do
    project 'API/HoelangTotTreinAPI.xcodeproj'

    target 'HoelangTotTreinAPITests' do
      inherit! :search_paths
    end
  end

  target 'HoelangTotTreinCore' do
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

	pod 'Promissum', :git => 'https://github.com/tomasharkema/Promissum.git', :commit => 'ff41d41ce367422e2d5c38c8d3115f815efb7970'
	pod 'Promissum/Alamofire', :git => 'https://github.com/tomasharkema/Promissum.git', :commit => 'ff41d41ce367422e2d5c38c8d3115f815efb7970'

  pod 'Statham', :git => 'https://github.com/tomasharkema/Statham.git', :commit => '698ffe0b57d4b7a46a8f48ad5ea8f927f63b0980'
  pod 'Statham/Alamofire+Promissum', :git => 'https://github.com/tomasharkema/Statham.git', :commit => '698ffe0b57d4b7a46a8f48ad5ea8f927f63b0980'
	pod 'RxSwift',    '~> 3.5'

  target 'HLTT Extension' do
    project 'App/HoelangTotTrein2.xcodeproj'
  end

  target 'HoelangTotTreinAPIWatch' do
    project 'API/HoelangTotTreinAPI.xcodeproj'
  end

  target 'HoelangTotTreinCoreWatch' do
    project 'Core/HoelangTotTreinCore.xcodeproj'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.2'
    end
  end
end
