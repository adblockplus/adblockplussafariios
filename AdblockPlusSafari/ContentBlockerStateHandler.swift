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

        let cbID = adblockPlus.contentBlockerIdentifier()
        contentBlockerIsEnabled(with: cbID)
            .retry(GlobalConstants.contentBlockerReloadRetryCount)
            .subscribe(onNext: { activated in
                self.adblockPlus.activated = activated
            }).disposed(by: bag)
    }

    /// Determine content blocker activation state. For iOS >= 10, use the content blocker API.
    /// For iOS < 10, use the legacy method.
    /// - Parameter identifier: Unique ID string for the content blocker.
    /// - Returns: Observable with true if activated, false otherwise.
    private func contentBlockerIsEnabled(with identifier: ContentBlockerIdentifier) -> Observable<Bool> {
        return Observable.create { observer in
            if #available(iOS 10.0, *) {
                SFContentBlockerManager
                    .getStateOfContentBlocker(withIdentifier: identifier,
                                              completionHandler: { state, error in
                        if let uwError = error {
                            observer.onError(uwError)
                        }
                        if let uwState = state {
                            let contentBlockerIsEnabled = uwState.isEnabled
                            observer.onNext(contentBlockerIsEnabled)
                            observer.onCompleted()
                        } else {
                            observer.onNext(false)
                            observer.onCompleted()
                        }
                    })
            } else {
                self.adblockPlus.performActivityTest(with: self.filterListsUpdater.cbManager)
            }
            return Disposables.create()
        }.observeOn(MainScheduler.asyncInstance)
    }
}
