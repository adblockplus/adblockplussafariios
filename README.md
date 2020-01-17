### ⚠️ Deprecated
This repository is for the 1.x version of Adblock Plus for iOS which has now been depricated.
Adblock Plus for iOS has been rewritten from the ground up and can be found in its [new repository here](https://gitlab.com/eyeo/adblockplus/adblock-plus-for-safari).


Adblock Plus for iOS
====================

A content blocker extension for Safari for iOS.

Building
--------

### Requirements

- [Xcode 9 or later](https://developer.apple.com/xcode/)
- [Carthage](https://github.com/Carthage/Carthage)
- [Sourcery](https://github.com/krzysztofzablocki/Sourcery)
- [SwiftLint](https://github.com/realm/SwiftLint/) (optional)

### Building in Xcode

1. Copy the file `ABP-Secret-API-Env-Vars.sh` (available internally) into the same directory as `AdblockPlusSafari.xcodeproj`.
2. Run `carthage update` to install additional Swift dependencies.
3. Open _AdblockPlusSafari.xcodeproj_ in Xcode.
4. Build and run the project locally in Xcode _or_ run `build.py` to export a build for distribution. After using `build.py`, the locally created `build` folder may need to be removed before building with Xcode will succeed.

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
