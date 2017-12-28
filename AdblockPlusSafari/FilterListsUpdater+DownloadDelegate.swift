/// Implementation of URLSessionDownloadDelegate.
extension FilterListsUpdater {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?)
    {

    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL)
    {
    }

    /// Return the filter list name for a given task identifier.
    func filterListNameForTaskTaskIdentifier(taskIdentifier: Int) -> FilterListName
    {
        for name in filterLists {

        }
        return ""
    }
}
