Adblock Plus for iOS
====================

A content blocker extension for Safari for iOS.

Building
--------

### Requirements

- [XCode 7 or later](https://developer.apple.com/xcode/)
- [CocoaPods](https://cocoapods.org/)

### Building in XCode

1. Run `pod install` to install the dependencies and generate the
   _AdblockPlusSafari_ workspace.
2. Open _AdblockPlusSafari.xcworkspace_ in XCode.
3. Archive and export the project. In order to export a build using one of the
   devbuild configurations, the code signing identity for host app and extension
   needs to be set manually.
