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

/// KVO keys.
enum ABPState: String {
    case filterLists
    case reloading
}

/// Shared instance that contains the active Adblock Plus instance.
/// This class holds the operations that were previously coupled to the Objective-C app delegate.
class ABPManager: NSObject {
    var bag: DisposeBag!

    /// For testing reloading KVO.
    var reloadingKeyValue: Int?

    /// Active instance of Adblock Plus.
    @objc dynamic var adblockPlus: AdblockPlusExtras! {
        /// Add kvo observers.
        didSet {
            setupKVO()
        }
    }

    /// This is a unique token (Int) that identifies a request to run in the background.
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier? {
        /// End the existing task before setting a new one.
        willSet {
            if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                if let uwBgTaskID = backgroundTaskIdentifier {
                    UIApplication.shared.endBackgroundTask(uwBgTaskID)
                }
            }
        }
    }

    private static var privateSharedInstance: ABPManager?
    private static let keyPaths: [ABPState] = [.filterLists, .reloading]
    private var firstUpdateTriggered: Bool = false
    private var backgroundFetches = [[String: Any]]()

    /// Destroy the shared instance in memory.
    class func destroy() {
        privateSharedInstance = nil
    }

    /// Access the shared instance.
    class func sharedInstance() -> ABPManager {
        guard let shared = privateSharedInstance else {
            privateSharedInstance = ABPManager()
            return privateSharedInstance!
        }
        return shared
    }

    /// Setup an initial Adblock Plus instance.
    override init() {
        super.init()
        defer {
            adblockPlus = AdblockPlusExtras()
        }
    }

    /// Cleanup Adblock Plus instance and observers.
    deinit {
        bag = nil
        adblockPlus = nil
    }

    // ------------------------------------------------------------
    // MARK: - Foreground mode -
    // ------------------------------------------------------------

    /// When the app becomes active, if there are outdated filter lists, update them.
    func handleDidBecomeActive() {
        adblockPlus.checkActivatedFlag()
        if !firstUpdateTriggered &&
           !adblockPlus.updating {
            let filterListNames: [String] = adblockPlus.outdatedFilterListNames()
            if filterListNames.count > 0 {
                adblockPlus.updateFilterLists(withNames: filterListNames,
                                              userTriggered: false)
                firstUpdateTriggered = true
            }
        }
    }

    // ------------------------------------------------------------
    // MARK: - Background mode -
    // ------------------------------------------------------------

    func handlePerformFetch(withCompletionHandler completion: @escaping (UIBackgroundFetchResult) -> Void) {
        let outdatedFilterListNames = adblockPlus.outdatedFilterListNames()
        if outdatedFilterListNames.count > 0 {
            var outdatedFilterLists = [String: Any]()
            for outdatedFilterListName in outdatedFilterListNames {
                outdatedFilterLists[outdatedFilterListName] = adblockPlus.filterLists[outdatedFilterListName]
            }
            adblockPlus.updateFilterLists(withNames: outdatedFilterListNames,
                                          userTriggered: false)
            backgroundFetches.append(["completion": completion,
                                      "filterLists": outdatedFilterLists,
                                      "startDate": Date()])
        } else {
            // No need to perform background refresh
            completion(UIBackgroundFetchResult.noData)
        }
    }

    /// Begin background tasks if filter lists are reloading.
    func handleDidEnterBackground() {
        if !adblockPlus.reloading {
            return
        }
        let expirationHandler: () -> Void = { [weak self] in
            self?.backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
        let app = UIApplication.shared
        backgroundTaskIdentifier = app.beginBackgroundTask(expirationHandler: expirationHandler)
    }

    /// Process events initiated by background URLSession requests.
    func handleEventsForBackgroundURLSession(identifier: String,
                                             completion: @escaping () -> Void) {
        whitelistedWebsites(forSessionID: identifier)
            .subscribe(onCompleted: {
                self.handleDidEnterBackground()
                completion()
            }).disposed(by: bag)
    }

    // ------------------------------------------------------------
    // MARK: - KVO -
    // ------------------------------------------------------------

    /// Subscribe to kvo updates.
    private func setupKVO() {
        bag = DisposeBag()
        let subs = [reloadingSubscription,
                    filterListsSubscription]
        _ = subs.map { $0().disposed(by: bag) }
    }

    /// Subscription of changes on reloading key.
    private func reloadingSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Bool.self,
                           ABPState.reloading.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: { reloading in
                guard let uwReloading = reloading else {
                    return
                }

                // Used for testing to verify that the reloading observer is active.
                self.reloadingKeyValue = uwReloading ? 1 : 0

                let app = UIApplication.shared
                let isBackground = (app.applicationState != UIApplicationState.active)
                let invalidBgTask = (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid)
                if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid &&
                   !uwReloading {
                    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
                }
                if invalidBgTask && uwReloading && isBackground {
                    self.backgroundTaskIdentifier = app.beginBackgroundTask(expirationHandler: { [weak self] in
                        self?.backgroundTaskIdentifier = UIBackgroundTaskInvalid
                    })
                }
            })
    }

    /// Subscription of changes on filterLists key.
    private func filterListsSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(NSDictionary.self,
                           ABPState.filterLists.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: { filterLists in
                guard filterLists != nil else {
                    return
                }
                self.checkFilterList()
            })
    }

    private func checkFilterList() {
        if adblockPlus.updating {
            for bgFetch in backgroundFetches {
                var updated = false
                let filterLists = bgFetch["filterLists"] as? [String: Any]
                if let uwFilterLists = filterLists {
                    for key in uwFilterLists.keys {
                        let filterList = uwFilterLists[key] as? [String: Any]
                        var lastUpdate: Date?
                        var currentLastUpdate: Date?
                        if let uwFilterList = filterList {
                            lastUpdate = uwFilterList["lastUpdate"] as? Date
                        }
                        if let uwFilterList = adblockPlus.filterLists[key] {
                            currentLastUpdate = uwFilterList["lastUpdate"] as? Date
                        }
                        updated = updated ||
                                  (lastUpdate == nil && currentLastUpdate != nil) ||
                                  ((currentLastUpdate != nil && lastUpdate != nil) && currentLastUpdate?.compare(lastUpdate!) == .orderedDescending)
                        if let uwCompletion = bgFetch["completion"] as? (UIBackgroundFetchResult) -> Void {
                            uwCompletion(updated ? UIBackgroundFetchResult.newData : UIBackgroundFetchResult.failed)
                        }
                    } // End for key
                }
                backgroundFetches = []
            } // End for bgFetch
        }
    }
}
