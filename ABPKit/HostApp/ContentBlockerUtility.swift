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

import RxCocoa
import RxSwift

/// Utility functions related to content blocking.
/// These support the ABP Safari iOS app.
public class ContentBlockerUtility {
    var bag: DisposeBag!
    let jsonExtension = "json"

    public init() {
        bag = DisposeBag()
    }

    /// Get NS item provider for a resource matching filter list rules.
    /// - parameter resource: Name of JSON filter list without extension
    /// - returns: NSItemProvider for the attachment
    public func getAttachment(resource: String) -> NSItemProvider? {
        let bndl = Bundle(for: ContentBlockerUtility.self)
        let itemProvider =
            NSItemProvider(contentsOf: bndl.url(forResource: resource,
                                                withExtension: jsonExtension))
        return itemProvider
    }

    /// Get filter list name based on the following legacy states:
    /// * acceptableAdsEnabled
    /// * defaultFilterListEnabled
    /// * State of custom filter list downloaded
    ///
    /// - returns: Name of filter list
    public func activeFilterListName() -> FilterListName? {
        let cstm = Constants.customFilterListName
        let dfltAA = Constants.defaultFilterListPlusExceptionRulesName
        let dflt = Constants.defaultFilterListName
        let relay = AppExtensionRelay.sharedInstance()
        if relay.acceptableAdsEnabled.value == true {
            return dfltAA
        } else if relay.defaultFilterListEnabled.value == true {
            return dflt
        } else {
            if let customList =
                try? getFilterList(for: cstm,
                                   filterLists: relay.filterLists.value) {
                if relay.defaultFilterListEnabled.value == true &&
                    customList.downloaded == true {
                    return cstm
                }
            }
        }
        return nil
    }

    /// Tell if a file corresponding to a filter list exists.
    /// - parameter filename: Name of file for filter list rules
    /// - returns: True if file exists, otherwise false
    func filterListFileExists(_ filename: String) -> Bool {
        let mgr = FileManager.default
        let cfg = Config()
        guard let group = try? cfg.appGroup() else {
            return false
        }
        var url = mgr.containerURL(forSecurityApplicationGroupIdentifier: group)
        url = url?.appendingPathComponent(filename,
                                          isDirectory: false)
        if mgr.fileExists(atPath: (url?.path)!) {
            return true
        }
        return false
    }

    /// Get the internal name of a Filter List model object.
    func filterListFilename(name: FilterListName) -> String {
        switch name {
        case Constants.defaultFilterListName:
            return Constants.defaultFilterListFilename
        case Constants.defaultFilterListPlusExceptionRulesName:
            return Constants.defaultFilterListPlusExceptionRulesFilename
        default:
            return ""
        }
    }

    /// Get the filter list rules file URL from the bundle.
    /// - returns: File URL for the filter list rules
    /// - throws: ABPFilterListError
    public func activeFilterListsURL() throws -> FilterListFileURL {
        let relay = AppExtensionRelay.sharedInstance()
        if relay.enabled.value == true {
            guard let name = activeFilterListName() else {
                throw ABPFilterListError.missingName
            }
            return try getFilterListFileURL(name: name)
        }
        throw ABPFilterListError.notFound
    }

    /// Retrieve a reference (file URL) to a blocklist file in persistent storage.
    /// - parameter name: The given name for a filter list.
    /// - parameter bundle: Defaults to config bundle.
    func getFilterListFileURL(name: FilterListName,
                              bundle: Bundle = Config().bundle()) throws -> FilterListFileURL {
        let ignoreDownloaded = false // don't check the downloaded flag for special cases
        guard let pstr = Persistor() else {
            throw ABPMutableStateError.missingDefaults
        }
        guard let models = try? pstr.loadFilterListModels() else {
            throw ABPFilterListError.invalidData
        }
        if let model = try? getFilterList(for: name,
                                          filterLists: models),
           let filename = model.fileName {
            if model.downloaded == true || ignoreDownloaded {
                if let url = bundle.url(forResource: filename,
                                        withExtension: "") {
                    return url
                } else {
                    throw ABPFilterListError.notFound
                }
            }
        }
        throw ABPFilterListError.notFound
    }

    func filenameFromURL(_ url: BlockListFileURL) -> BlockListFilename {
        return url.lastPathComponent
    }

    func mergedFilterListRules(from sourceURL: BlockListFileURL,
                               with whitelistedWebsites: WhitelistedWebsites,
                               limitRuleMaxCount: Bool = false) -> Observable<BlockListFileURL> {
        let maxRuleCount = 1 // for unit testing only
        let filename = "ww-\(filenameFromURL(sourceURL))"
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let dir = self.rulesDir(blocklist: sourceURL)
        let dest = self.makeNewBlocklistFileURL(name: filename,
                                                at: dir)
        guard let rulesData = try? self.blocklistData(blocklist: sourceURL) else {
            return Observable.error(ABPFilterListError.invalidData)
        }
        guard let ruleList = try? decoder.decode(V1FilterList.self,
                                                 from: rulesData) else {
            return Observable.error(ABPFilterListError.failedDecoding)
        }
        // swiftlint:disable unused_optional_binding
        guard let _ = try? self.startBlockListFile(blocklist: dest) else {
            return Observable.error(ABPFilterListError.failedFileCreation)
        }
        // swiftlint:enable unused_optional_binding
        var cnt = 0
        return ruleList.rules()
            .takeWhile({ _ in
                if limitRuleMaxCount {
                    return cnt < maxRuleCount
                }
                return true
            })
            .flatMap { (rule: BlockingRule) -> Observable<BlockListFileURL> in
                cnt += 1
                guard let coded = try? encoder.encode(rule) else {
                    return Observable.error(ABPFilterListError.failedEncodeRule)
                }
                self.writeToEndOfFile(blocklist: dest,
                                      with: coded)
                self.addRuleSeparator(blocklist: dest)
                return Observable.create { observer in
                    whitelistedWebsites.forEach {
                        let rule = self.makeWhitelistRule(domain: $0)
                        guard let data = try? encoder.encode(rule) else {
                            observer.onError(ABPFilterListError.failedEncodeRule)
                            return
                        }
                        self.writeToEndOfFile(blocklist: dest,
                                              with: data)
                        self.addRuleSeparator(blocklist: dest)
                    }
                    self.endBlockListFile(blocklist: dest)
                    observer.onNext(dest)
                    observer.onCompleted()
                    return Disposables.create()
                }
            }
    }

    // ------------------------------------------------------------
    // MARK: - Private -
    // ------------------------------------------------------------
    // May be set as public for testing.

    /// Get a local FilterList struct for a given list name.
    /// - parameters:
    ///   - name: Filter list name
    ///   - filterLists: Array of lists
    /// - returns: Filter list struct
    /// - throws: ABPFilterListError
    public func getFilterList(for name: FilterListName,
                              filterLists: [FilterList]) throws -> FilterList {
        var cnt = 0
        for list in filterLists where list.name == name {
            cnt += 1
            return list
        }
        throw ABPFilterListError.notFound
    }
}
