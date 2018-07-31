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

import RxCocoa

/// This class is for passing legacy states from the host app to the app extension.
@objc
public class AppExtensionRelay: NSObject {
    private static var privateSharedInstance: AppExtensionRelay?

    // ------------------------------------------------------------
    // MARK: - Legacy host app states -
    // ------------------------------------------------------------

    public var downloadedVersion = BehaviorRelay<Int?>(value: nil)
    public var enabled = BehaviorRelay<Bool?>(value: nil)
    public var filterLists = BehaviorRelay<[libadblockplus_ios.FilterList]>(value: [])
    public var installedVersion = BehaviorRelay<Int?>(value: nil)
    public var lastActivity = BehaviorRelay<Date?>(value: nil)
    public var whitelistedWebsites = BehaviorRelay<[String]>(value: [])

    // End legacy host app states

    /// Destroy the shared instance in memory.
    class func destroy() {
        privateSharedInstance = nil
    }

    /// Access the shared instance.
    @objc
    public class func sharedInstance() -> AppExtensionRelay {
        guard let shared = privateSharedInstance else {
            privateSharedInstance = AppExtensionRelay()
            return privateSharedInstance!
        }
        return shared
    }

    @objc
    public func legacyDownloadedVersionSet(_ downloadedVersion: Int) {
        self.downloadedVersion.accept(downloadedVersion)
    }

    @objc
    public func legacyEnabledSet(_ enabled: Bool) {
        self.enabled.accept(enabled)
    }

    @objc
    public func legacyFilterListsSet(_ filterLists: LegacyFilterLists) {
        var swiftLists = [FilterList]()
        for key in filterLists.keys {
            if let list = FilterList(named: key,
                                     fromDictionary: filterLists[key]) {
                swiftLists.append(list)
            }
        }
        self.filterLists.accept(swiftLists)
    }

    @objc
    public func legacyInstalledVersionSet(_ installedVersion: Int) {
        self.installedVersion.accept(installedVersion)
    }

    @objc
    public func legacyLastActivitySet(_ lastActivity: Date) {
        self.lastActivity.accept(lastActivity)
    }

    @objc
    public func legacyWhitelistedWebsitesSet(_ whitelistedWebsites: [String]) {
        self.whitelistedWebsites.accept(whitelistedWebsites)
    }
}
