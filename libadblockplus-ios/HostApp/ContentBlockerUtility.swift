import RxCocoa

/// Utility functions related to content blocking.
public class ContentBlockerUtility {
    public init() {
        // Left empty.
    }

    /// Get a local FilterList struct for a given list name.
    /// - parameters:
    ///   - name: Filter list name
    ///   - filterLists: Array of lists
    /// - returns: Filter list struct
    /// - throws: ABPFilterListError
    func getFilterList(for name: FilterListName,
                       filterLists: [FilterList]) throws -> FilterList {
        var cnt = 0
        for list in filterLists where list.name == name {
            cnt += 1
            return list
        }
        throw ABPFilterListError.notFound
    }

    func getFilterListFileURL(name: FilterListName) throws -> FilterListFileURL {
        let ignoreDownloaded = true
        let relay = AppExtensionRelay.sharedInstance()
        if relay.enabled.value == true {
            let lists = relay.filterLists.value
            if let list =
                try? getFilterList(for: name,
                                   filterLists: lists) {
                if (list.downloaded == true || ignoreDownloaded) &&
                   list.fileName != nil {
                    let bndl = Bundle(for: ContentBlockerUtility.self)
                    if let url = bndl.url(forResource: list.fileName!,
                                          withExtension: "") {
                        return url
                    } else { throw ABPFilterListError.notFound }
                }
            }
        }
        throw ABPFilterListError.notFound
    }
}
