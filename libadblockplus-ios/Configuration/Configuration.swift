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

/// Type aliases.
public typealias ContentBlockerIdentifier = String
public typealias FilterListLastVersion = String
public typealias FilterListName = String
public typealias FilterListV2Rules = [[String: [String: String]]]
public typealias FilterListV2Sources = [[String: String]]
public typealias WhiteListedWebsite = String

/// Constants that are global to the framework.
struct Constants {
    /// Default interval for expiration of a filter list.
    static let defaultFilterListExpiration: TimeInterval = 86400
}

public struct Config {
    let baseProduct = "AdblockPlusSafari"
    let adblockPlusSafariExtension = "AdblockPlusSafariExtension"
    let adblockPlusSafariActionExtension = "AdblockPlusSafariActionExtension"

    public init() {
        // Left empty
    }

    private func bundleName() -> String? {
        if let comps = Bundle.main.bundleIdentifier?.components(separatedBy: ".") {
            var newComps = [String]()
            if comps.last == adblockPlusSafariExtension ||
                comps.last == adblockPlusSafariActionExtension {
                newComps = Array(comps[0...1])
            } else {
                newComps = Array(comps[0...2])
            }
            return newComps.joined(separator: ".")
        }
        return nil
    }

    /// A copy of the content blocker identifier function found in the legacy ABP implementation.
    /// - Returns: A content blocker ID such as "org.adblockplus.devbuilds.AdblockPlusSafari" or nil
    public func contentBlockerIdentifier() -> ContentBlockerIdentifier? {
        if let name = bundleName() {
            return "\(name).\(baseProduct).\(adblockPlusSafariExtension)"
        }
        return nil
    }
}
