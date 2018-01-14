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

/// Handle filter list updating.
///
/// This replaces the former Objective-C implementation of AdblockPlusExtras.
///
/// It makes use of struct FilterList to represent a filter list. Therefore,
/// the **Swift model struct should always be used when interacting with this
/// class.**
///
/// Filter lists on the Objective-C side are [String :[String: Any]] or a
/// dictionary of dictionaries.
class FilterListsUpdater: AdblockPlusShared,
                          URLSessionDownloadDelegate {
    let updatingKey = "updatingGroupIdentifier"
    var reloadBag: DisposeBag! = DisposeBag()

    /// For download tasks.
    var backgroundSession: URLSession!

    /// Filter list download tasks keyed by URL string.
    var downloadTasks = [FilterListName: URLSessionTask]()

    /// This identifier is incremented every time filter lists are updated.
    /// See updateFilterLists:withNames:userTriggered.
    @objc var updatingGroupIdentifier = 0

    /// Handles reloading of the content blocker.
    var cbManager: ContentBlockerManagerProtocol!

    /// Reference to active ABPManager that must not be nil. Without this
    /// reference, accessing the ABP Manager shared instance will be circular
    /// since the ABP Manager has a strong reference to the Filter List
    /// updater and makes an updater in its init.
    weak var abpManager: ABPManager!

    /// Process running tasks and add a reloading observer.
    ///
    /// Because the ABPManager initializes an instance of this class in its
    /// init, the shared instance of ABPManager cannot be used within the init
    /// of this class without forming a circular reference. Therefore, a
    /// reference to the ABP Manager is passed in and stored as a property.
    init(abpManager: ABPManager) {
        super.init()
        cbManager = ContentBlockerManager()
        self.abpManager = abpManager
        backgroundSession = newBackgroundSession()
        removeUpdatingGroupID()

        // Turn off the error dialog during init. If filter list updating is interrupted after this
        // the error dialog will be shown.
        abpManager.adblockPlus.needsDisplayErrorDialog = false

        processRunningTasks()
    }

    // ------------------------------------------------------------
    // MARK: - URL Session -
    // ------------------------------------------------------------

    /// Make the URL session used for downloading filter lists.
    func newBackgroundSession() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: backgroundSessionConfigurationIdentifier())
        return URLSession(configuration: config,
                          delegate: self,
                          delegateQueue: .main)
    }

    /// Remove the updating state key from a filter list.
    private func removeUpdatingGroupID() {
        let lists = abpManager.filterLists()
        var newLists = [FilterList]()
        for var list in lists {
            list.updatingGroupIdentifier = nil
            newLists.append(list)
        }
        abpManager.saveFilterLists(newLists)
    }

    /// Update the state of all filter lists. If there is a task to complete,
    /// save a new download task.
    private func processRunningTasks() {
        backgroundSession.getAllTasks(completionHandler: { tasks in
            let lists = self.abpManager?.filterLists()
            var listsToRemoveUpdatingFrom = [FilterListName]()
            for list in lists! {
                listsToRemoveUpdatingFrom.append(list.name!)
            }

            // Remove filter lists whose tasks are still running.
            for task in tasks {
                var found = false
                var listIndex = 0
                for list in lists! {
                    if let url = task.originalRequest?.url?.absoluteString {
                        if url == list.url &&
                           task.taskIdentifier == list.taskIdentifier {
                            self.downloadTasks[url] = task
                            var nameIndex = 0
                            for name in listsToRemoveUpdatingFrom {
                                if name == list.name {
                                    listsToRemoveUpdatingFrom.remove(at: nameIndex)
                                    break
                                }
                                nameIndex += 1
                            }
                        } else {
                            // If a task was interrupted, then it is cancelled here. This handles
                            // the case where the app crashes or is forced to quit during a download
                            // task. The user receives an alert and is able to redo what had
                            // previously failed.
                            task.cancel()
                        }
                        found = true
                        break
                    }
                    listIndex += 1
                } // End for list
                if !found {
                    task.cancel()
                }
            } // End for task

            // Set updating to false for lists that don't have tasks.
            self.abpManager?.setNotUpdating(forNames: listsToRemoveUpdatingFrom)
        })
    }

    /// Store and start a download task.
    func startDownloadTask(forFilterListName name: FilterListName,
                           task: URLSessionDownloadTask?) {
        guard let uwTask = task else {
            return
        }
        downloadTasks[name]?.cancel()
        downloadTasks[name] = uwTask
        uwTask.resume()
    }

    // ------------------------------------------------------------
    // MARK: - Filter Lists -
    // ------------------------------------------------------------

    func updateActiveFilterList(userTriggered: Bool) {
        let activeFilterList = activeFilterListName()
        updateFilterLists(withNames: [activeFilterList],
                          userTriggered: userTriggered)
    }

    /// Update filter lists with statuses of tasks running while the app is in the background.
    @objc
    func updateFilterLists(withNames names: [FilterListName],
                           userTriggered: Bool) {
        if names.count == 0 { return }
        updatingGroupIdentifier += 1
        var modifiedFilterLists = [String: FilterList]()
        for name in names {
            if var filterList = FilterList(withName: name,
                                           fromDictionary: self.filterLists[name]) {
                if let urlString = filterList.url,
                   let url = URL(string: urlString) {
                    let task = backgroundSession.downloadTask(with: url)
                    startDownloadTask(forFilterListName: name,
                                      task: task)
                    filterList.taskIdentifier = task.taskIdentifier
                }
                filterList.updating = true
                filterList.updatingGroupIdentifier = updatingGroupIdentifier
                filterList.userTriggered = userTriggered
                filterList.lastUpdateFailed = false
                modifiedFilterLists[name] = filterList

                // Write the filter list back to the Objective-C side.
                replaceFilterList(withName: name,
                                  withNewList: filterList)
            }
        }
    }

    /// Examine the current filter lists and return an array of filter list
    /// names that are outdated.
    func outdatedFilterListNames() -> [FilterListName] {
        var outdated = [FilterListName]()
        for key in filterLists.keys {
            if let uwList = FilterList(withName: key,
                                       fromDictionary: filterLists[key]) {
                if uwList.expired() {
                    outdated.append(key)
                }
            }
        }
        return outdated
    }

    /// Set whether acceptable ads will be enabled or not. The content blocker
    /// filter lists are reloaded after a state change triggered by the user.
    /// Enabling acceptable ads will also enable the content blocker if it is
    /// disabled.
    ///
    /// - parameter enabled: true if acceptable ads are enabled
    @objc
    func changeAcceptableAds(enabled: Bool) {
        super.enabled = enabled
        reload(afterCompletion: { [weak self] in
            if let names = self?.outdatedFilterListNames() {
                self?.updateFilterLists(withNames: names,
                                        userTriggered: false)
            }
        })
    }

    /// Set whether the default filter list be used or not. The content
    /// blocker filter lists are reloaded after the state change.
    ///
    /// - parameter enabled: true if the default filter list is enabled
    func setDefaultFilterListEnabled(enabled: Bool) {
        super.defaultFilterListEnabled = enabled
        reload(withCompletion: { _ in
            self.updateFilterLists(withNames: self.outdatedFilterListNames(),
                                   userTriggered: false)
        })
    }

    // ------------------------------------------------------------
    // MARK: - Reload Content Blocker -
    // ------------------------------------------------------------

    /// Start a completion closure, then reload the content blocker.
    func reload(afterCompletion completion: () -> Void) {
        abpManager.disableReloading = true
        completion()
        abpManager.disableReloading = false
        reload(withCompletion: nil)
    }

    /// Reload the content blocker, then run a completion closure.
    @objc
    func reload(withCompletion completion: ((Error?) -> Void)?) {
        guard abpManager.disableReloading == false else {
            return
        }
        abpManager.adblockPlus.reloading = true
        abpManager.adblockPlus.performingActivityTest = false
        reloadBag = DisposeBag()
        reloadContentBlocker(withCompletion: completion)
            .subscribe()
            .disposed(by: reloadBag)
    }

    /// This is the base function for reloading the content blocker. A
    /// ContentBlockerManager performs the actual reload. Errors in reloading
    /// are currently not handled.
    func reloadContentBlocker(withCompletion completion: ((Error?) -> Void)?) -> Observable<Void> {
        return Observable.create { observer in
            let id = self.contentBlockerIdentifier()
            self.cbManager.reload(withIdentifier: id) { error in
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
