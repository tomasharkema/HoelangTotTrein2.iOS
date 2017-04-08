#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

xcodebuild "-workspace" "HoelangTotTrein2.xcworkspace" "-scheme" "HoelangTotTrein2" "clean" "build" | xcpretty