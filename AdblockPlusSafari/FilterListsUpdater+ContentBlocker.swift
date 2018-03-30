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

extension FilterListsUpdater {
    /// Start a completion closure, then reload the content blocker.
    /// - Parameter completion: Closure to run **before** reload.
    func reloadContentBlocker(afterCompletion completion: () -> Void) {
        abpManager.disableReloading = true
        completion()
        abpManager.disableReloading = false
        reloadContentBlocker(withCompletion: nil)
    }

    /// Reload the content blocker, then run a completion closure.
    /// - Parameter completion: Closure to run after reload.
    @objc
    func reloadContentBlocker(withCompletion completion: ((Error?) -> Void)?) {
        guard abpManager.disableReloading == false else { return }

        // Dispose all current reloads before doing another. This comes before property changes to
        // isolate KVO observer interactions.
        reloadBag = DisposeBag()

        abpManager.adblockPlus.reloading = true
        abpManager.adblockPlus.performingActivityTest = false
        contentBlockerReload(withCompletion: completion)
            .subscribe()
            .disposed(by: reloadBag)
    }

    /// This is the base function for reloading the content blocker. A ContentBlockerManager
    /// performs the actual reload. Errors in reloading are currently not handled.
    /// - Parameter completion: Closure to run after reload even if an error occurred.
    /// - Returns: An Observable.
    fileprivate func contentBlockerReload(withCompletion completion: ((Error?) -> Void)?) -> Observable<Void> {
        return Observable.create { observer in
            let cbID = self.contentBlockerIdentifier()
            self.cbManager.reload(withIdentifier: cbID) { error in
                self.abpManager.adblockPlus.reloading = false
                if completion != nil {
                    completion!(error)
                    observer.onCompleted()
                } else {
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }.observeOn(MainScheduler.asyncInstance)
    }
}
