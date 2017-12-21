import SafariServices

/// Performs operations with the Safari content blocker manager.
class ContentBlockerManager: NSObject,
                             ContentBlockerManagerProtocol {
    func reload(withIdentifier identifier: String,
                completionHandler: ((Error?) -> Void)? = nil) {
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier,
                                                     completionHandler: completionHandler)
    }
}
