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

/// Implementation of URLSessionDownloadDelegate and related support functions.
extension FilterListsUpdater {
    // ------------------------------------------------------------
    // MARK: - URLSessionDownloadDelegate -
    // ------------------------------------------------------------

    /// A URL session task has finished transferring data.
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        let name = filterListNameForTaskTaskIdentifier(taskIdentifier: task.taskIdentifier)
        guard let uwName = name else { return }
        guard var list = filterList(withName: name) else { return }
        list.lastUpdateFailed = true
        list.updating = false
        list.taskIdentifier = nil
        replaceFilterList(withName: uwName,
                          withNewList: list)
        removeDownloadTask(forFilterListName: uwName)
    }

    /// A download task for a filter list has finished downloading.
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let name = filterListNameForTaskTaskIdentifier(taskIdentifier: downloadTask.taskIdentifier)
        guard let uwName = name else { return }
        guard var list = filterList(withName: name) else { return }
        let response = downloadTask.response as? HTTPURLResponse
        if !validURLResponse(response) {
            return
        }
        let fileManager = FileManager.default
        let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: group())
        let destination = containerURL?.appendingPathComponent(list.fileName!,
                                                               isDirectory: false)
        moveOrReplaceItem(source: location,
                          destination: destination)
        list.lastUpdate = Date()
        list.downloaded = true
        list.lastUpdateFailed = false
        list.updating = false
        list.taskIdentifier = nil
        downloadedVersion += 1

        // Test parsing of the filter list.
        let bridge = FilterListSwiftBridge(dictionary: list.toDictionary()!)

        do {
            try bridge.parseFilterList(from: destination!)
        } catch {
            return
        }

        // Save the modified filter list.
        replaceFilterList(withName: uwName,
                          withNewList: list)
    }

    // ------------------------------------------------------------
    // MARK: - Private -
    // ------------------------------------------------------------

    /// Move a file to a destination. If the file exists, it will be first removed, if possible.
    private func moveOrReplaceItem(source: URL,
                                   destination: URL?) {
        let fileManager = FileManager.default
        let destPath = destination!.path
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
                                          to: destination!)
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
        let lists: [FilterList] = abpManager!.filterLists()
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
        let lists = abpManager!.filterLists()
        var result: FilterListName?
        var cnt = 0
        for list in lists where list.taskIdentifier == taskIdentifier {
            result = list.name
            cnt += 1
        }
        assert(cnt == 0 || cnt == 1)
        return result
    }

    /// Remove a key-value pair from the download tasks.
    private func removeDownloadTask(forFilterListName name: FilterListName) {
        var removeName: FilterListName?
        var cnt = 0
        for key in downloadTasks.keys where key == name {
            removeName = name
            cnt += 1
        }
        assert(cnt == 0 || cnt == 1)
        if let name = removeName {
            downloadTasks[name] = nil
        }
    }
}
