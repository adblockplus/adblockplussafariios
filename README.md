Adblock Plus for iOS
====================

A content blocker extension for Safari for iOS.

Building
--------

### Requirements

- [Xcode 9 or later](https://developer.apple.com/xcode/)
- [Carthage](https://github.com/Carthage/Carthage)
- [SwiftLint](https://github.com/realm/SwiftLint/) (optional)

### Building in Xcode

1. Run `carthage update` to install additional Swift dependencies.
2. Open _AdblockPlusSafari.xcodeproj_ in Xcode.
3. Archive and export the project. In order to export a build using one of the
devbuild configurations, the code signing identity for host app and extension
needs to be set manually.

### Changing Xcode configurations

To switch between company and enterprise accounts, there are eight (8) changes to be made at the
following locations with the values listed in respective order.

* Target **AdblockPlusSafari**
    - General > Bundle Identifier = (org.adblockplus.AdblockPlusSafari ||
org.adblockplus.devbuilds.AdblockPlusSafari)
    - General > Team = (Company || Enterprise)
    - Capabilities > App Groups = (group.org.adblockplus.AdblockPlusSafari ||
group.org.adblockplus.devbuilds.AdblockPlusSafari)
    - Edit scheme > Build Configuration = (Debug || Devbuild Debug)
* Target **AdblockPlusSafariActionExtension**
    - General > Bundle Identifier =
    (org.adblockplus.AdblockPlusSafari.AdblockPlusSafariActionExtension ||
    org.adblockplus.devbuilds.AdblockPlusSafari.AdblockPlusSafariActionExtension)
    - General > Team = (Company || Enterprise)
* Target **AdblockPlusSafariExtension**
    - General > Bundle Identifier = (org.adblockplus.AdblockPlusSafari.AdblockPlusSafariExtension
    || org.adblockplus.devbuilds.AdblockPlusSafari.AdblockPlusSafariExtension)
    - General > Team = (Company || Enterprise)

Xcode may need to be restarted before the changes will take effect. When the changes are
complete, the app should be able to run on a simulator or a device.
