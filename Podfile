workspace 'HoelangTotTrein2.xcworkspace'

abstract_target 'HoelangTotTrein2Pods' do
	use_frameworks!
  platform :ios, '13.0'

  pod 'Firebase/Core'

	target 'HoelangTotTrein2' do
    use_frameworks!

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
end

#abstract_target 'HoelangTotTrein2WatchPods' do
#	use_frameworks!
#	platform :watchos, '3.0'
#
#	target 'HLTT Extension' do
#		project 'App/HoelangTotTrein2.xcodeproj'
#	end
#end
