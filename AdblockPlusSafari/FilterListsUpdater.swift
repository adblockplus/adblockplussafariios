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
    var downloadTasks: [String: URLSessionTask]?
    var updatingGroupIdentifier = 0
    var cbManager: ContentBlockerManagerProtocol?

    /// Maximum date for lastUpdated.
    var lastUpdate: Date {
            var lists = self.filterLists.keys.map { key in
                    return FilterList(fromDictionary: self.filterLists[key])
                }
            return .distantPast
        }

    /// Process running tasks and add a reloading observer.
    override init() {
        dLog("", date: "2017-Oct-24")
        super.init()
        cbManager = ContentBlockerManager()
        removeUpdatingGroupID()
        processRunningTasks()
        addReloadingObserver()
    }

    /// Remove the updating state key from a filter list.
    func removeUpdatingGroupID() {
        dLog("", date: "2017-Oct-24")
        for key in filterLists.keys {
            filterLists[key]?.removeValue(forKey: updatingKey)
        }
    }

    /// Is there where background tasks are processed?
    func processRunningTasks() {
        dLog("", date: "2017-Oct-24")
        let config = URLSessionConfiguration.background(withIdentifier: backgroundSessionConfigurationIdentifier())
        backgroundSession = URLSession(configuration: config,
                                            delegate: self,
                                            delegateQueue: OperationQueue.main)
        backgroundSession?.getAllTasks(completionHandler: { tasks in
            // Remove filter lists whose tasks are still running
        })
    }

    ///
    func updateFilterLists(withNames names: [FilterListName],
                           userTriggered: Bool) {
        if names.count == 0 { return }
        updatingGroupIdentifier += 1
        var modifiedFilterLists = [String: FilterList]()
        for name in names {
            if var filterList = FilterList(fromDictionary: self.filterLists[name]) {
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
        guard var tasks = downloadTasks,
              let uwTask = task else { return }
        tasks[name]?.cancel()
        tasks[name] = uwTask
        uwTask.resume()
    }

    // ------------------------------------------------------------
    // MARK: - Filter Lists -
    // ------------------------------------------------------------

    /// Return an array of filter list names that are outdated.
    func outdatedFilterListNames() -> [FilterListName] {
        var outdated = [FilterListName]()
        for key in filterLists.keys {
            if let uwList = FilterList(fromDictionary: filterLists[key]) {
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

//        let id = self.contentBlockerIdentifier()
//        dLog("reloading \(id)", date: "2017-Dec-20")
//        dLog("completion \(String(describing: completion))", date: "2017-Dec-21")

//        ContentBlockerManager().reload(withIdentifier: id) { error in
//        DispatchQueue.global(qos: .default).async {
////            DispatchQueue.main.async {
//                // Handle error
//                dLog("error after reload: \(error)", date: "2017-Dec-21")
//                ABPManager.sharedInstance().adblockPlus.reloading = false
//                ABPManager.sharedInstance().adblockPlus.checkActivatedFlag(lastActivity!)
//                dLog("💯 fin reload", date: "2017-Dec-20")
//                dLog("completion \(completion)", date: "2017-Dec-21")
//                if completion != nil {
//                    completion!(error)
//                }
//            }
//        }

        reloadContentBlocker(withCompletion: completion)

//            .observeOn(scheduler)
//            .subscribeOn(scheduler)
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

                //            DispatchQueue.main.async {
                // Handle error
                dLog("error after reload: \(String(describing: error))", date: "2017-Dec-21")
                ABPManager.sharedInstance().adblockPlus.reloading = false
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
