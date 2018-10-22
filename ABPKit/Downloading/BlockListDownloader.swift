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

public
class BlockListDownloader: NSObject,
                           URLSessionDownloadDelegate {
    let updatingKey = "updatingGroupIdentifier"
    let cfg = Config()
    var pstr: Persistor!
    /// True indicates testing.
    var isTest = false
    /// For download tasks.
    var backgroundSession: URLSession!
    /// For download tasks.
    var foregroundSession: URLSession!
    /// Filter list download tasks keyed by task ID.
    var downloadTasksByID = [UIBackgroundTaskIdentifier: URLSessionTask]()
    /// Download events keyed by task ID.
    var downloadEvents = [UIBackgroundTaskIdentifier: BehaviorSubject<DownloadEvent>]()

    // MARK: - Legacy Properties -

    /// This identifier is incremented every time filter lists are updated. See updateFilterLists:withNames:userTriggered.
    @objc var updatingGroupIdentifier = 0
    /// Setter used during legacy refactoring.
    var setLegacyReloading: ((Bool) -> Void)?
    /// Setter used during legacy refactoring.
    var setLegacyPerformingActivityTest: ((Bool) -> Void)?
    var downloadedVersion: Int!

    public override
    init() {
        super.init()
        pstr = Persistor()
        downloadedVersion = 0
    }

    /// For legacy ABP Safari iOS:
    public
    init(legacyReloadingSetter: @escaping (Bool) -> Void,
         legacyPerformingActivityTestSetter: @escaping (Bool) -> Void) {
        self.setLegacyReloading = legacyReloadingSetter
        self.setLegacyPerformingActivityTest = legacyPerformingActivityTestSetter
        super.init()
        pstr = Persistor()
        downloadedVersion = 0
    }

    /// A filter list download task is created. An entry in the download tasks dictionary is
    /// created for the task.
    ///
    /// Testing this function with a local URL only works when the download is in the foreground.
    /// - parameter filterList: A filter List model object.
    /// - parameter runInBackground: If true, a background session will be used.
    /// - returns: A download task observable.
    func blockListDownload(for filterList: ABPKit.FilterList,
                           runInBackground: Bool = true) -> Observable<URLSessionDownloadTask> {
        guard let urlString = filterList.source,
            let url = URL(string: urlString),
            var components = URLComponents(string: url.absoluteString)
        else {
            return Observable.error(ABPDownloadTaskError.failedToMakeDownloadTask)
        }
        return Observable.create { observer in
            components.queryItems = FilterListDownloadData(with: filterList).queryItems
            components.encodePlusSign()
            if let newURL = components.url {
                var task: URLSessionDownloadTask!
                if runInBackground {
                    guard let bgSession = try? self.newBackgroundSession() else {
                        observer.onError(ABPDownloadTaskError.failedToMakeBackgroundSession)
                        return Disposables.create()
                    }
                    self.backgroundSession = bgSession
                    task = self.backgroundSession.downloadTask(with: newURL)
                } else {
                    self.foregroundSession = self.newForegroundSession()
                    task = self.foregroundSession.downloadTask(with: newURL)
                }
                let identifier = UIBackgroundTaskIdentifier(rawValue: task.taskIdentifier)
                self.downloadTasksByID[identifier] = task
                observer.onNext(task)
                observer.onCompleted()
            } else {
                observer.onError(ABPDownloadTaskError.failedToMakeDownloadTask)
            }
            return Disposables.create()
        }
    }

    /// Make the URL session used for downloading filter lists.
    private
    func newBackgroundSession() throws -> URLSession {
        guard let bgID = try? cfg.backgroundSessionConfigurationIdentifier() else {
            throw ABPConfigurationError.invalidBundlePrefix
        }
        let config =
            URLSessionConfiguration
                .background(withIdentifier: bgID)
        return URLSession(configuration: config,
                          delegate: self,
                          delegateQueue: .main)
    }

    private
    func newForegroundSession() -> URLSession {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config,
                          delegate: self,
                          delegateQueue: .main)
    }

    /// Get last event from behavior subject matching the task ID.
    /// - parameter taskID: A background task identifier.
    /// - returns: The download event value if it exists, otherwise nil.
    internal
    func lastDownloadEvent(taskID: UIBackgroundTaskIdentifier) -> DownloadEvent? {
        if let subject = downloadEvents[taskID] {
            if let lastEvent = try? subject.value() {
                return lastEvent
            }
        }
        return nil
    }

    /// Return true if the status code is valid.
    internal
    func validURLResponse(_ response: HTTPURLResponse?) -> Bool {
        if isTest { return true }
        if let uwResponse = response {
            let code = uwResponse.statusCode
            if code >= 200 && code < 300 {
                return true
            }
        }
        return false
    }
}
