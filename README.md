# HoelangTotTrein2.iOS
Hi there! 👋 Welcome to the HLTTv2 repository. This is my scholarship entry for WWDC 2016.

### _HoelangTotTrein: How long 'till train_


=========

# Installation

- Run pod install

`pod install`

- Open the project via the workspace

`open HoelangTotTrein2.xcworkspace`

- Enjoy!

=========

# Features

- Geofence for start, change and arrival.
- SmartFare for convienient 
- (background) Push notifications for delays
- watchOS 2 app for easy access from the wrist
- Memorizes your current advice; 

=========

# API

This project makes use of [NSApi.Scala](https://github.com/tomasharkema/NSApi.Scala) (an JSON wrapper for [The NS API](http://www.ns.nl/en/travel-information/ns-api)'s XML/SOAP api) for it's travel data.

=========

# Future plans

- Wrap other open travel data such as for the [Deutsche Bahn](http://data.deutschebahn.com/apis/fahrplan/), [BART](http://www.bart.gov/schedules/developers/api), or any other API that offers an advice api with delay support.
- Make watchOS app more independed of the main app.
- implement significant location monitoring to track wherether the user will begin on it's journey
