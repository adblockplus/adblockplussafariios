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

/// Implementation of URLSessionDownloadDelegate and related support functions.
extension FilterListsUpdater {

    /// Get last event from behavior subject matching the task ID.
    /// - Parameter taskID: A background task identifier.
    /// - Returns: The download event value if it exists, otherwise nil.
    func lastDownloadEvent(taskID: UIBackgroundTaskIdentifier) -> DownloadEvent? {
        if let subject = downloadEvents[taskID] {
            if let lastEvent = try? subject.value() {
                return lastEvent
            }
        }
        return nil
    }

    // ------------------------------------------------------------
    // MARK: - URLSessionDownloadDelegate -
    // ------------------------------------------------------------

    /// A URL session task is transferring data.
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if var lastEvent = lastDownloadEvent(taskID: downloadTask.taskIdentifier) {
            lastEvent.totalBytesWritten = totalBytesWritten
            downloadEvents[downloadTask.taskIdentifier]?.onNext(lastEvent) // make a new event
        }
    }

    /// A URL session task has finished transferring data.
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if var lastEvent = lastDownloadEvent(taskID: task.taskIdentifier) {
            lastEvent.error = error
            lastEvent.errorWritten = true
            downloadEvents[task.taskIdentifier]?.onNext(lastEvent)
        }
        let name = filterListNameForTaskTaskIdentifier(taskIdentifier: task.taskIdentifier)
        guard let uwName = name else { return }
        guard var list = filterList(withName: name) else { return }
        list.lastUpdateFailed = true
        list.updating = false
        list.taskIdentifier = nil
        replaceFilterList(withName: uwName,
                          withNewList: list)
        downloadTasksByID[task.taskIdentifier] = nil
    }

    /// A download task for a filter list has finished downloading. Update the user's filter list
    /// metadata and move the downloaded file. Future optimization can include retrying the
    /// post-download operations if an error is encountered.
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {

        if var lastEvent = lastDownloadEvent(taskID: downloadTask.taskIdentifier) {
            lastEvent.didFinishDownloading = true
            downloadEvents[downloadTask.taskIdentifier]?.onNext(lastEvent) // new event
        }

        let name = filterListNameForTaskTaskIdentifier(taskIdentifier: downloadTask.taskIdentifier)
        guard let uwName = name else { return }
        guard var list = filterList(withName: name) else { return }
        let response = downloadTask.response as? HTTPURLResponse
        if !validURLResponse(response) {
            return
        }
        let fileManager = FileManager.default
        let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: group())
        guard let fileName = list.fileName else { return }
        let destination = containerURL?.appendingPathComponent(fileName,
                                                               isDirectory: false)
        moveOrReplaceItem(source: location,
                          destination: destination)
        list.lastUpdate = Date()
        list.downloaded = true
        list.lastUpdateFailed = false
        list.updating = false
        list.taskIdentifier = nil
        downloadedVersion += 1

        // Test parsing of the filter list and set the version.
        guard let objcList = list.toDictionary() else { return }
        let bridge = FilterListSwiftBridge(dictionary: objcList)
        guard let uwDestination = destination else { return }
        do {
            try bridge.parseFilterList(from: uwDestination)
            try setVersion(url: uwDestination,
                           filterList: &list)
        } catch {
            return
        }

        // Save the modified filter list.
        replaceFilterList(withName: uwName,
                          withNewList: list)
    }

    /// Parse the v2 filter list version and set it on the internal filter list model struct.
    /// - Parameters:
    ///   - url: Local URL where the list is saved.
    ///   - filterList: Internal model struct for the list.
    /// - Throws: ABP error if parsing fails.
    func setVersion(url: URL,
                    filterList: inout FilterList) throws {
        do {
            let data = try Data(contentsOf: url,
                                options: .uncached)
            let json = JSONFilterList(with: data)
            filterList.version = json?.version
        } catch {
            throw ABPFilterListError.invalidData
        }
    }

    // ------------------------------------------------------------
    // MARK: - Private -
    // ------------------------------------------------------------

    /// Move a file to a destination. If the file exists, it will be first removed, if possible.
    /// If the operation cannot be completed, the function will return without an error.
    private func moveOrReplaceItem(source: URL,
                                   destination: URL?) {
        guard let uwDestination = destination else { return }
        let fileManager = FileManager.default
        let destPath = uwDestination.path
        let exists = fileManager.fileExists(atPath: destPath)
        var removeError: Error?
        if exists {
            do { try fileManager.removeItem(atPath: destPath)
            } catch let error {
                removeError = error
            }
        }
        if removeError == nil {
            do { try fileManager.moveItem(at: source,
                                          to: uwDestination)
            } catch {
                // Move error occurred.
                return
            }
        } else {
            // Remove error occurred.
            return
        }
    }

    /// Return true if the status code is valid.
    private func validURLResponse(_ response: HTTPURLResponse?) -> Bool {
        if let uwResponse = response {
            let code = uwResponse.statusCode
            if code >= 200 && code < 300 {
                return true
            }
        }
        return false
    }

    /// Replace an existing filter list with a new one.
    internal func replaceFilterList(withName name: String,
                                    withNewList newList: FilterList) {
        guard let abpMgr = abpManager else { return }
        var lists = abpMgr.filterLists()
        var index = 0
        var replaceIndex: Int?
        var cnt = 0
        for list in lists {
            if list.name == name {
                replaceIndex = index
                cnt += 1
            }
            index += 1
        }
        assert(cnt == 0 || cnt == 1)
        if let uwReplaceIndex = replaceIndex {
            lists[uwReplaceIndex] = newList
        }
        abpMgr.saveFilterLists(lists)
    }

    private func filterList(withName name: String?) -> FilterList? {
        guard name != nil else { return nil }
        guard let uwAbpManager = abpManager else { return nil }
        let lists: [FilterList] = uwAbpManager.filterLists()
        var result: FilterList?
        var cnt = 0
        for list in lists where list.name == name {
            cnt += 1
            result = list
        }
        assert(cnt == 0 || cnt == 1)
        return result
    }

    /// Return the filter list name for a given task identifier.
    private func filterListNameForTaskTaskIdentifier(taskIdentifier: Int) -> FilterListName? {
        guard let uwAbpManager = abpManager else { return nil }
        let lists = uwAbpManager.filterLists()
        var result: FilterListName?
        var cnt = 0
        for list in lists where list.taskIdentifier == taskIdentifier {
            result = list.name
            cnt += 1
        }
        assert(cnt == 0 || cnt == 1)
        return result
    }
}
