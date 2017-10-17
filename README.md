Adblock Plus for iOS
====================

A content blocker extension for Safari for iOS.

Building
--------

### Requirements

- [XCode 9 or later](https://developer.apple.com/xcode/)
- [Carthage](https://github.com/Carthage/Carthage)
- [SwiftLint](https://github.com/realm/SwiftLint/) (optional)

### Building in XCode

1. Run `carthage update` to install additional Swift dependencies.
2. Open _AdblockPlusSafari.xcodeproj_ in XCode.
3. Archive and export the project. In order to export a build using one of the
   devbuild configurations, the code signing identity for host app and extension
   needs to be set manually.
