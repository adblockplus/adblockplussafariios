import RxCocoa
import RxSwift
import SafariServices

/// This replaces the former Objective-C implementation of AdblockPlusExtras.
///
/// It makes use of struct FilterList to represent a filter list.
///
/// Therefore, the **Swift model struct should always be used when interacting with this class.**
///
/// self.filterLists is what type?
/// Filter lists are [String :[String: Any]] - Dictionary of dictionaries
class FilterListsUpdater: AdblockPlusShared,
                          URLSessionDownloadDelegate,
                          FileManagerDelegate {
    let updatingKey = "updatingGroupIdentifier"
    let bag = DisposeBag()
    weak var backgroundSession: URLSession?

    /// Filter list download tasks keyed by URL string.
    var downloadTasks = [String: URLSessionTask]()

    var updatingGroupIdentifier = 0
    var cbManager: ContentBlockerManagerProtocol?

    /// Maximum date for lastUpdated.
    var lastUpdate: Date {
            var lists = self.filterLists.keys.map { key in
                    return FilterList(withName: key,
                                      fromDictionary: self.filterLists[key])
                }
            return .distantPast
        }

    /// Process running tasks and add a reloading observer.
    override init() {
        dLog("🍺 - should only be called once", date: "2017-Oct-24")
        super.init()
        cbManager = ContentBlockerManager()
        removeUpdatingGroupID()

        // DZ: Needs setting of _needsDisplayErrorDialog

        processRunningTasks()
        addReloadingObserver()
    }

    /// Remove the updating state key from a filter list.
    private func removeUpdatingGroupID() {
        dLog("", date: "2017-Oct-24")
        for key in filterLists.keys {
            filterLists[key]?.removeValue(forKey: updatingKey)
        }
    }

    /// Update the state of all filter lists. If there is a task to complete, save a new download task.
    private func processRunningTasks() {
        dLog("Process running tasks", date: "2017-Oct-24")
        let config = URLSessionConfiguration.background(withIdentifier: backgroundSessionConfigurationIdentifier())
        backgroundSession = URLSession(configuration: config,
                                       delegate: self,
                                       delegateQueue: OperationQueue.main)
        backgroundSession?.getAllTasks(completionHandler: { tasks in
            let lists = ABPManager.sharedInstance().filterLists()
            var listsToRemoveUpdatingFrom = [FilterListName]()

            // Remove filter lists whose tasks are still running.
            for task in tasks {
                var found = false
                var listIndex = 0
                for list in lists
                {
                    if let url = task.originalRequest?.url?.absoluteString
                    {
                        if url == list.url &&
                           task.taskIdentifier == list.taskIdentifier
                        {
                            dLog("♣️ dl task", date: "2017-Dec-27")
                            self.downloadTasks[url] = task
                        }
                        else
                        {
                            // If a task was interrupted, then it is cancelled here.
                            // This handles the case where the app crashes or is forced
                            // to quit during a download task. The user receives an alert
                            // and is able to redo what had previously failed.
                            dLog("♣️ cancel", date: "2017-Dec-27")
                            task.cancel()
                        }
                        found = true
                        if let name = list.name {
                            listsToRemoveUpdatingFrom.append(name)
                        }
                        break
                    }
                    listIndex += 1
                } // End for list
                if !found
                {
                    dLog("🔫 cancelling", date: "2017-Dec-27")
                    task.cancel()
                }
            } // End for task

            // Set updating to false for lists that don't have tasks.
            ABPManager.sharedInstance().setNotUpdating(forNames: listsToRemoveUpdatingFrom)
        })
    }

    /// Update filter lists with statuses of tasks running while the app is in the background.
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
                    let task = backgroundSession?.downloadTask(with: url)
                    startDownloadTask(forFilterListName: name,
                                      task: task)
                    filterList.taskIdentifier = task?.taskIdentifier
                }
                filterList.updating = true
                filterList.updatingGroupIdentifier = updatingGroupIdentifier
                filterList.userTriggered = userTriggered
                filterList.lastUpdateFailed = false
                modifiedFilterLists[name] = filterList
            }
        }
        // DZ: Write the filterlists back to the Objective-C side.
    }

    /// Store and start a download task.
    func startDownloadTask(forFilterListName name: FilterListName,
                           task: URLSessionDownloadTask?)
    {
        dLog("🌋", date: "2017-Dec-27")
        guard let uwTask = task else { return }
        downloadTasks[name]?.cancel()
        downloadTasks[name] = uwTask
        uwTask.resume()
    }

    // ------------------------------------------------------------
    // MARK: - Filter Lists -
    // ------------------------------------------------------------

    /// Return an array of filter list names that are outdated.
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

    // ------------------------------------------------------------
    // MARK: - Reloading -
    // ------------------------------------------------------------

    /// Is the where the filter list reloads?
    ///
    /// Observe the reloading state of ABP.
    func addReloadingObserver() {
        dLog("adding observer", date: "2017-Dec-20")

        let nc = NotificationCenter.default
        nc.rx.notification(NSNotification.Name.UIApplicationWillEnterForeground,
                           object: nil)
            .subscribe { event in
                self.synchronize()
                let abp = ABPManager.sharedInstance().adblockPlus
                dLog("reloading state = \(abp?.reloading)", date: "2017-Dec-20")
                if abp?.reloading == true { return }
                abp?.performActivityTest(with: ContentBlockerManager())
            }.disposed(by: bag)
    }

    /// Set whether acceptable ads will be enabled or not.
    /// The content blocker filter lists are reloaded after the state change.
    /// Enabling acceptable ads will also enable the content blocker if it is disabled.
    /// - parameter enabled: true if acceptable ads are enabled
    ///
    /// DZ: Check if this is correct
    @objc func changeAcceptableAds(enabled: Bool) {
        super.enabled = enabled
        reload(afterCompletion: { [weak self] in
            if let names = self?.outdatedFilterListNames() {
                self?.updateFilterLists(withNames: names,
                                        userTriggered: false)
            }
        })
    }

    /// Set whether the default filter list be used or not.
    /// The content blocker filter lists are reloaded after the state change.
    /// - parameter enabled: true if the default filter list is enabled
    func setDefaultFilterListEnabled(enabled: Bool) {
        super.defaultFilterListEnabled = enabled
        reload(withCompletion: { error in
            self.updateFilterLists(withNames: self.outdatedFilterListNames(),
                                   userTriggered: false)
        })
    }

    /// Start a completion closure, then reload the content blocker.
    func reload(afterCompletion completion: () -> Void) {
        ABPManager.sharedInstance().disableReloading = true
        completion()
        ABPManager.sharedInstance().disableReloading = false
        reload(withCompletion: nil)
    }

    /// Reload the content blocker, then run a completion closure.
    func reload(withCompletion completion: ((Error?) -> Void)?) {
        guard ABPManager.sharedInstance().disableReloading == false else {
            dLog("reloading disabled", date: "2017-Dec-20")
            return
        }
        let lastActivity = self.lastActivity
        ABPManager.sharedInstance().adblockPlus.reloading = true
        ABPManager.sharedInstance().adblockPlus.performingActivityTest = false

        reloadContentBlocker(withCompletion: completion)
            .subscribe(onCompleted: {
                dLog("💯 fin reload", date: "2017-Dec-20")
            }).disposed(by: bag)
    }

    func reloadContentBlocker(withCompletion completion: ((Error?) -> Void)?) -> Observable<Void>
    {
        return Observable.create { observer in
            let id = self.contentBlockerIdentifier()
            dLog("reloading \(id)", date: "2017-Dec-20")
            dLog("completion \(String(describing: completion))", date: "2017-Dec-21")
            self.cbManager?.reload(withIdentifier: id) { error in
                // DZ: Handle error
                dLog("error after reload: \(String(describing: error))", date: "2017-Dec-21")
                ABPManager.sharedInstance().adblockPlus.reloading = false
                dLog("🦈 fin reload", date: "2017-Dec-26")
                ABPManager.sharedInstance().adblockPlus.checkActivatedFlag(self.lastActivity!)

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
    // MARK: - Private -
    // ------------------------------------------------------------

    /// Handle notification of app entering the foreground.
    private func onApplicationWillEnterForegroundNotification(notification: Notification)
    {
        synchronize()

        if ABPManager.sharedInstance().adblockPlus.reloading {
            return
        }

        ABPManager.sharedInstance().adblockPlus.performActivityTest(with: ContentBlockerManager())
    }
}
