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
import SafariServices

/// Handle the state of the content blocker including
/// * Determine content blocker activation state
/// * Save content blocker activation state
class ContentBlockerStateHandler {
    var bag: DisposeBag! = DisposeBag()
    var adblockPlus: AdblockPlusExtras!
    var filterListsUpdater: FilterListsUpdater!

    /// Construct a state handler.
    /// - Parameters:
    ///   - adblockPlus: Legacy adblockplus object.
    ///   - filterListsUpdater: Reference to a filter list updater.
    init(adblockPlus: AdblockPlusExtras,
         filterListsUpdater: FilterListsUpdater) {
        self.adblockPlus = adblockPlus
        self.filterListsUpdater = filterListsUpdater
    }

    /// Detect if the content blocker is activated (enabled) and update the stored state.
    func updateActivation() {
        adblockPlus.synchronize()
        guard !adblockPlus.reloading else { return }

        // Dispose all update operations first.
        filterListsUpdater.reloadBag = DisposeBag()

        guard let cbID = Config().contentBlockerIdentifier() else { return }
        // Activation of the content blocker will not happen without a valid identifier.
        let reloading = { value in self.adblockPlus.reloading = value }
        let performingActivityTest = { value in self.adblockPlus.performingActivityTest = value }
        let safariCB =
            libadblockplus_ios.SafariContentBlocker(reloadingSetter: reloading,
                                                    performingActivityTestSetter: performingActivityTest)
        if #available(iOS 10.0, *) {
            safariCB.contentBlockerIsEnabled(with: cbID)
                .retry(GlobalConstants.contentBlockerReloadRetryCount)
                .subscribe(onNext: { activated in
                    self.adblockPlus.activated = activated
                }).disposed(by: bag)
        } else {
            handleLegacyContentBlockerIsEnabled(with: cbID)
        }
    }

    /// Determine content blocker activation state for iOS < 10 using the legacy activity test.
    /// - Parameter identifier: Unique ID string for the content blocker.
    private func handleLegacyContentBlockerIsEnabled(with identifier: ContentBlockerIdentifier) {
        DispatchQueue.main.async {
            self.adblockPlus.performActivityTest(with: self.filterListsUpdater.cbManager)
        }
    }
}
