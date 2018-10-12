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

/// This class is for encapsulating legacy mutable states and configuration
/// values.
///
/// It also serves the following purposes
/// * An intermediary between the host app and app extension.
/// * Translate between Objective-C and Swift types during the migration of the
/// legacy app to ABPKit.
///   - The related selectors are prefixed with `legacy` for this purpose.
///
/// Usage:
///
///     let relay = AppExtensionRelay.sharedInstance()
///
@objc
public class AppExtensionRelay: NSObject {
    private static var privateSharedInstance: AppExtensionRelay?

    // ------------------------------------------------------------
    // MARK: - Legacy host app states -
    // ------------------------------------------------------------

    public var acceptableAdsEnabled = BehaviorRelay<Bool?>(value: nil)
    public var customFilterListEnabled = BehaviorRelay<Bool?>(value: nil)
    public var defaultFilterListEnabled = BehaviorRelay<Bool?>(value: nil)
    public var downloadedVersion = BehaviorRelay<Int?>(value: nil)
    public var enabled = BehaviorRelay<Bool?>(value: nil)
    public var filterLists = BehaviorRelay<[ABPKit.FilterList]>(value: [])
    public var group = BehaviorRelay<String?>(value: nil)
    public var installedVersion = BehaviorRelay<Int?>(value: nil)
    public var lastActivity = BehaviorRelay<Date?>(value: nil)
    public var shouldRespondToActivityTest = BehaviorRelay<Bool?>(value: nil)
    public var whitelistedWebsites = BehaviorRelay<[String]>(value: [])

    // End legacy host app states

    override private init() {
        let cfg = Config()
        guard let grp = try? cfg.appGroup() else {
            return
        }
        self.group.accept(grp)
    }

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

    // ------------------------------------------------------------
    // MARK: - Legacy getters -
    // ------------------------------------------------------------

    @objc
    public func legacyContentBlockerIdentifier() -> ContentBlockerIdentifier? {
        return Config().contentBlockerIdentifier()
    }

    @objc
    public func legacyGroup() -> AppGroupName? {
        return group.value
    }

    // ------------------------------------------------------------
    // MARK: - Legacy setters -
    // ------------------------------------------------------------

    @objc
    public func legacyAcceptableAdsEnabledSet(_ acceptableAdsEnabled: Bool) {
        self.acceptableAdsEnabled.accept(acceptableAdsEnabled)
    }

    @objc
    public func legacyCustomFilterListEnabledSet(_ customFilterListEnabled: Bool) {
        self.customFilterListEnabled.accept(customFilterListEnabled)
    }

    @objc
    public func legacyDefaultFilterListEnabledSet(_ defaultFilterListEnabled: Bool) {
        self.defaultFilterListEnabled.accept(defaultFilterListEnabled)
    }

    @objc
    public func legacyDownloadedVersionSet(_ downloadedVersion: Int) {
        self.downloadedVersion.accept(downloadedVersion)
    }

    @objc
    public func legacyEnabledSet(_ enabled: Bool) {
        self.enabled.accept(enabled)
    }

    /// Add all Swift filter list structs from the legacy type.
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
