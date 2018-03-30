/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-present eyeo GmbH
 *
 * Adblock Plus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Adblock Plus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

/// Provides functions for getting device dependent active version data.
class ABPActiveVersions {
    /// Version key for the app.
    private static let versionKey = "CFBundleShortVersionString"
    /// Identifier for active WebKit.
    private static let webkitID = "com.apple.WebKit"
    /// Key containing active WebKit version.
    private static let webkitVersionKey = "CFBundleVersion"

    /// - Returns: Version of the app.
    class func appVersion() -> String? {
        return Bundle.main.infoDictionary?[versionKey] as? String
    }

    /// - Returns: Current WebKit version as a string.
    class func webkitVersion() -> String? {
        let webkit = Bundle(identifier: webkitID)
        if let dict = webkit?.infoDictionary,
           let version = dict[webkitVersionKey] as? String {
            return version
        }
        return nil
    }

    /// - Returns: Current iOS version as a string.
    class func iosVersion() -> String {
        let osv = ProcessInfo().operatingSystemVersion
        return "\(osv.majorVersion).\(osv.minorVersion).\(osv.patchVersion)"
    }
}
