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
import RxSwift
import SafariServices

/// Observers can subscribe the following states:
/// * reloading
/// * performingActivityTest
@objc
public class SafariContentBlocker: NSObject {
    /// Reloading state.
    public var reloading = BehaviorRelay<Bool>(value: false)
    /// Performing activity test state.
    public var performingActivityTest = BehaviorRelay<Bool>(value: false)
    /// Legacy flag used to disable reloading within the class.
    private var disableReloading: Bool!
    /// Legacy setter.
    private var reloadingSetter: ((Bool) -> Void)!
    /// Legacy setter.
    private var performingActivityTestSetter: ((Bool) -> Void)!
    /// Bag for reload operations.
    private var reloadBag: DisposeBag! = DisposeBag()

    /// Helps maintain compatibility with legacy implementation. The legacy setters will
    /// eventually be removed and the behavior relays will be the exclusive means of state
    /// observation.
    @objc
    public init(reloadingSetter: @escaping (Bool) -> Void,
                performingActivityTestSetter: @escaping (Bool) -> Void) {
        disableReloading = false
        self.reloadingSetter = reloadingSetter
        self.performingActivityTestSetter = performingActivityTestSetter
    }

    /// Start a completion closure, then reload the content blocker.
    /// - parameter completion: Escaping closure to run **before** reload.
    public func reloadContentBlocker(after completion: @escaping () -> Void) {
        disableReloading = true
        completion()
        disableReloading = false
        reloadContentBlocker(completion: nil)
    }

    /// Reload the content blocker, then run a completion closure.
    /// - parameter completion: Escaping closure to run after reload.
    @objc
    public func reloadContentBlocker(completion: ((Error?) -> Void)?) {
        guard disableReloading == false else { return }

        // Dispose all current reloads before doing another. This comes before property changes to
        // isolate KVO observer interactions.
        reloadBag = DisposeBag()

        reloadingSetter?(true)
        reloading.accept(true)
        performingActivityTestSetter?(false)
        performingActivityTest.accept(false)
        contentBlockerReload(completion: completion)
            .subscribe()
            .disposed(by: reloadBag)
    }

    /// This is the base function for reloading the content blocker. A ContentBlockerManager
    /// performs the actual reload. Errors in reloading are currently not handled.
    /// - parameter completion: Escaping closure to run after reload even if an error occurred.
    /// - returns: An Observable.
    private func contentBlockerReload(completion: ((Error?) -> Void)?) -> Observable<Void> {
        return Observable.create { observer in
            guard let cbID = Config().contentBlockerIdentifier() else {
                observer.onError(ABPContentBlockerError.invalidIdentifier)
                return Disposables.create()
            }
            SFContentBlockerManager.reloadContentBlocker(withIdentifier: cbID) { error in
                self.reloadingSetter?(false)
                self.reloading.accept(false)
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

    // ------------------------------------------------------------
    // MARK: - State handling -
    // ------------------------------------------------------------

    /// Determine content blocker activation state for iOS >= 10.
    /// - Parameter identifier: Unique ID string for the content blocker.
    /// - Returns: Observable with true if activated, false otherwise.
    public func contentBlockerIsEnabled(with identifier: ContentBlockerIdentifier) -> Observable<Bool> {
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
            }
            return Disposables.create()
        }.observeOn(MainScheduler.asyncInstance)
    }
}
