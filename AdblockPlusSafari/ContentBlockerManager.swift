import SafariServices

/// Performs operations with the SFContentBlockerManager
class ContentBlockerManager: NSObject,
                             ContentBlockerManagerProtocol
{
    func reload(withIdentifier identifier: String,
                completionHandler: ((Error?) -> Void)? = nil)
    {
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier,
                                                     completionHandler: completionHandler)
    }
}
