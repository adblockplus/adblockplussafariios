/// Implementation of URLSessionDownloadDelegate.
extension FilterListsUpdater {
//    func urlSession(_ session: URLSession,
//                    task: URLSessionTask,
//                    didCompleteWithError error: Error?)
//    {
//        dLog("", date: "2017-Dec-28")
//    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        dLog("", date: "2017-Dec-28")
    }

//    func urlSession(_ session: URLSession,
//                    downloadTask: URLSessionDownloadTask,
//                    didFinishDownloadingTo location: URL)
//    {
//        dLog("", date: "2017-Dec-28")
//    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        dLog("", date: "2017-Dec-28")
    }

    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, removingItemAt URL: URL) -> Bool {
        return true
    }

    /// Return the filter list name for a given task identifier.
    func filterListNameForTaskTaskIdentifier(taskIdentifier: Int) -> FilterListName
    {
        dLog("", date: "2017-Dec-28")
        for name in filterLists {

        }
        return ""
    }
}
