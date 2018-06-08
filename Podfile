workspace 'HoelangTotTrein2.xcworkspace'

abstract_target 'HoelangTotTrein2Pods' do
	use_frameworks!
  	platform :ios, '10.0'

	pod 'Promissum'

	pod 'RxSwift', '~> 4.0'
	pod 'RxCocoa'
  pod 'SWXMLHash'

	target 'HoelangTotTrein2' do
    use_frameworks!
    platform :ios, '10.0'
		project 'App/HoelangTotTrein2.xcodeproj'

		pod 'R.swift'
		pod 'SegueManager/R.swift'
		pod 'AFDateHelper'
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
      pod 'RxTest'
    end
  end

end

abstract_target 'HoelangTotTrein2WatchPods' do
	use_frameworks!
	platform :watchos, '3.0'

	pod 'Promissum'
	pod 'RxSwift', '~> 4.0'
  pod 'SWXMLHash'

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

