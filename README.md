# HoelangTotTrein2.iOS
Hi there! 👋 Welcome to the HLTTv2 repository. 

This also is scholarship entry for WWDC 2016.

### _HoelangTotTrein: How long 'till train_

# About

Hoelang Tot Trein is a public transport app for the dutch railways. It helps the daily commuter to quickly provide it with the right info on the right time. Most importantly; how much time do I have untill the next train leaves.

Currently, version 1.0 is live in the App Store, but I'm working very hard to release this version 2 to the App Store. If you want to participate in the beta test, please send me a message.

# Features

- Geofence for start, change and arrival.
- Reverse-advice on arrival
- (background) Push notifications for delays
- watchOS 2 app for easy access from the wrist
- Memorizes your current advice; 

# Installation

- Run pod install

`pod install`

- Open the project via the workspace

`open HoelangTotTrein2.xcworkspace`

- Enjoy!

# API

This project makes use of [NSApi.Scala](https://github.com/tomasharkema/NSApi.Scala) (an JSON wrapper for [The NS API](http://www.ns.nl/en/travel-information/ns-api)'s XML/SOAP api) for it's travel data.


# Future plans

- Wrap other open travel data such as for the [Deutsche Bahn](http://data.deutschebahn.com/apis/fahrplan/), [BART](http://www.bart.gov/schedules/developers/api), or any other API that offers an advice api with delay support.
- Make watchOS app more independed of the main app.
- implement significant location monitoring to track wherether the user will begin on it's journey
