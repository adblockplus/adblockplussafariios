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

import Foundation

/// This file contains constants intended for global scope.

/// Type aliases.
public typealias AppGroupName = String
public typealias BlockListData = Data
public typealias BlockListDirectoryURL = URL
public typealias BlockListFilename = String
public typealias BlockListFileURL = URL
public typealias BundleName = String
public typealias BundlePrefix = String
public typealias ContentBlockerIdentifier = String
public typealias DefaultsSuiteName = String
public typealias DownloadEventID = String
public typealias FilterListFileURL = URL
public typealias FilterListID = String
public typealias FilterListLastVersion = String
public typealias FilterListName = String
public typealias FilterListV2Sources = [[String: String]]
public typealias LegacyFilterLists = [String: [String: Any]]
public typealias WhitelistedHostname = String
public typealias WhitelistedWebsites = [String]

/// Constants that are global to the framework.
public struct Constants {
    /// Limit for background operations, less than the allowed limit to allow time for content blocker reloading.
    static let backgroundOperationLimit: TimeInterval = 28
    /// Default interval for expiration of a filter list.
    public static let defaultFilterListExpiration: TimeInterval = 86400
    /// Internal name.
    public static let customFilterListName = "customFilterList"
    /// Internal name.
    public static let defaultFilterListName = "easylist"
    /// Internal name.
    public static let defaultFilterListPlusExceptionRulesName = "easylist+exceptionrules"
    /// On-disk name.
    public static let defaultFilterListFilename = "easylist_content_blocker.json"
    /// On-disk name.
    // swiftlint:disable identifier_name
    public static let defaultFilterListPlusExceptionRulesFilename = "easylist+exceptionrules_content_blocker.json"
    // swiftlint:enable identifier_name
    /// On-disk name.
    public static let emptyFilterListFilename = "empty.json"
    /// On-disk name.
    public static let customFilterListFilename = "custom.json"

    public static let blocklistEncoding = String.Encoding.utf8
    public static let blocklistArrayStart = "["
    public static let blocklistArrayEnd = "]"
    public static let blocklistRuleSeparator = ","

    public static let organization = "org.adblockplus"

    /// Internal distribution label for eyeo.
    public static let devbuildsName = "devbuilds"
}

/// ABPKit configuration class for accessing globally relevant functions.
public class Config {
    let baseProduct = "AdblockPlusSafari"
    let adblockPlusSafariExtension = "AdblockPlusSafariExtension"
    let adblockPlusSafariActionExtension = "AdblockPlusSafariActionExtension"
    let backgroundSession = "BackgroundSession"

    public init() {
        // Left empty
    }

    /// References the host app.
    /// Returns app identifier prefix such as:
    /// * org.adblockplus.devbuilds or
    /// * org.adblockplus
    private func bundlePrefix() -> BundlePrefix? {
        if let comps = Bundle.main.bundleIdentifier?.components(separatedBy: ".") {
            var newComps = [String]()
            if comps.contains(Constants.devbuildsName) {
                newComps = Array(comps[0...2])
            } else {
                newComps = Array(comps[0...1])
            }
            return newComps.joined(separator: ".")
        }
        return nil
    }

    /// Bundle reference for resources including:
    /// * bundled blocklists
    public func bundle() -> Bundle {
        return Bundle(for: Config.self)
    }

    public func appGroup() throws -> AppGroupName {
        if let name = bundlePrefix() {
            let grp = "group.\(name).\(baseProduct)"
            return grp
        }
        throw ABPContentBlockerError.invalidAppGroup
    }

    /// This suite name comes from the legacy app.
    public func defaultsSuiteName() throws -> DefaultsSuiteName {
        guard let name = try? appGroup() else {
            throw ABPMutableStateError.missingsDefaultsSuiteName
        }
        return name
    }

    /// A copy of the content blocker identifier function found in the legacy ABP implementation.
    /// - returns: A content blocker ID such as
    ///            "org.adblockplus.devbuilds.AdblockPlusSafari.AdblockPlusSafariExtension" or nil
    public func contentBlockerIdentifier() -> ContentBlockerIdentifier? {
        if let name = bundlePrefix() {
            return "\(name).\(baseProduct).\(adblockPlusSafariExtension)"
        }
        return nil
    }

    public func backgroundSessionConfigurationIdentifier() throws -> String {
        guard let prefix = bundlePrefix() else {
            throw ABPConfigurationError.invalidBundlePrefix
        }
        return "\(prefix).\(baseProduct).\(backgroundSession)"
    }
}
