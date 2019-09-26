workspace 'HoelangTotTrein2.xcworkspace'

abstract_target 'HoelangTotTrein2Pods' do
	use_frameworks!
  platform :ios, '12.0'

  pod 'Firebase/Core'

	target 'HoelangTotTrein2' do
    use_frameworks!
		project 'App/HoelangTotTrein2.xcodeproj'

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
    end
  end

end

abstract_target 'HoelangTotTrein2WatchPods' do
	use_frameworks!
	platform :watchos, '3.0'

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
