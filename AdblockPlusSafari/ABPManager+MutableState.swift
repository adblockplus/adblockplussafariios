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

import libadblockplus_ios
import RxSwift

// For relaying changes in mutable state in the legacy implementation.
extension ABPManager {
    func legacyAcceptableAdsEnabledSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Bool.self,
                           ABPState.acceptableAdsEnabled.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyAcceptableAdsEnabledSet(val)
                }
            })
    }

    func legacyCustomFilterListEnabledSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Bool.self,
                           ABPState.customFilterListEnabled.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyCustomFilterListEnabledSet(val)
                }
            })
    }

    func legacyDefaultFilterListEnabledSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Bool.self,
                           ABPState.defaultFilterListEnabled.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyDefaultFilterListEnabledSet(val)
                }
            })
    }

    func legacyDownloadedVersionSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Int.self,
                           ABPState.downloadedVersion.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyDownloadedVersionSet(val)
                }
            })
    }

    func legacyEnabledSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Bool.self,
                           ABPState.enabled.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyEnabledSet(val)
                }
            })
    }

    func legacyInstalledVersionSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Int.self,
                           ABPState.installedVersion.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyInstalledVersionSet(val)
                }
            })
    }

    func legacyLastActivitySubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Date.self,
                           ABPState.lastActivity.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyLastActivitySet(val)
                }
            })
    }

    func legacyWhiteListedWebsitesSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Array<WhitelistedHostname>.self,
                           ABPState.whiteListedWebsites.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: {
                if let val = $0 {
                    AppExtensionRelay
                        .sharedInstance()
                        .legacyWhitelistedWebsitesSet(val)
                }
            })
    }
}
