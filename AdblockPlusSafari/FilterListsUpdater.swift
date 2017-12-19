import RxCocoa
import RxSwift

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
                          FileManagerDelegate
{
    let updatingKey = "updatingGroupIdentifier"
    let bag = DisposeBag()
    weak var backgroundSession: URLSession?
    var downloadTasks: [String: URLSessionTask]?
    var updatingGroupIdentifier = 0
    var disableReloading: Bool?

    /// Max date for lastUpdated
    var lastUpdate: Date
    {
        get
        {
            var lists = self.filterLists.keys.map
                { key in
                    return FilterList(fromDictionary: self.filterLists[key])
                }
            return .distantPast
        }
    }

    override init()
    {
        dLog("", date: "2017-Oct-24")
        super.init()
        removeUpdatingGroupID()
        processRunningTasks()
        addReloadingObserver()
    }

    /// Remove the updating state key from a filter list
    func removeUpdatingGroupID()
    {
        dLog("", date: "2017-Oct-24")
        for key in filterLists.keys
        {
            self.filterLists[key]?.removeValue(forKey: updatingKey)
        }
    }

    /// Is there where background tasks are processed?
    func processRunningTasks()
    {
        dLog("", date: "2017-Oct-24")
        let config = URLSessionConfiguration.background(withIdentifier: backgroundSessionConfigurationIdentifier())
        self.backgroundSession = URLSession(configuration: config,
                                            delegate: self,
                                            delegateQueue: OperationQueue.main)
        backgroundSession?.getAllTasks(completionHandler: { tasks in
            // Remove filter lists whose tasks are still running
        })
    }

    /// Is the where the filter list reloads?
    func addReloadingObserver()
    {
        print("💯 reloading")
        let nc = NotificationCenter.default
        nc.rx.notification(NSNotification.Name.UIApplicationWillEnterForeground,
                           object: nil)
            .subscribe
            { event in
                self.synchronize()
                let abp = ABPManager.sharedInstance().adblockPlus
                if abp?.reloading == true { return }
                abp?.performActivityTest(with: ContentBlockerManager())
            }.disposed(by: bag)
    }

    struct ScheduledTasks
    {

    }

    func updateFilterLists(withNames names: [FilterListName],
                           userTriggered: Bool)
    {
        if names.count == 0 { return }

        self.updatingGroupIdentifier += 1

        var modifiedFilterLists = [String: FilterList]()
        var scheduledTasks = [String: URLSessionTask]()

        for name in names {
            if var filterList = FilterList(fromDictionary: self.filterLists[name]) {

                if let urlString = filterList.url,
                   let url = URL(string: urlString) {
                    let task = self.backgroundSession?.downloadTask(with: url)
                    scheduledTasks[name] = task
                    filterList.taskIdentifier = task?.taskIdentifier
                }
                
                filterList.updating = true
                filterList.updatingGroupIdentifier = self.updatingGroupIdentifier
                filterList.userTriggered = userTriggered
                filterList.lastUpdateFailed = false
                modifiedFilterLists[name] = filterList
            }
        }

        // Write the filterlists back to the Objective-C side.
    }

    func convertFilterListsToObjC()
    {

    }

    /// Return an array of filter list names that are outdated.
    func outdatedFilterListNames() -> [FilterListName]
    {
        var outdated = [FilterListName]()
        for key in filterLists.keys {
            if let uwList = FilterList(fromDictionary: filterLists[key])
            {
                if uwList.expired()
                {
                    outdated.append(key)
                }
            }
        }
        return outdated
    }

    // ------------------------------------------------------------
    // MARK: - URLSessionDownloadDelegate -
    // ------------------------------------------------------------

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL)
    {
    }
}
