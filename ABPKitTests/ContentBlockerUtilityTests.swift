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

@testable import ABPKit

import RxSwift
import XCTest

class ContentBlockerUtilityTests: XCTestCase {
    let timeout: TimeInterval = 5
    var util: ContentBlockerUtility!
    var relay: AppExtensionRelay!
    var bag: DisposeBag!
    let whitelistDomains =
        ["test1.com",
         "test2.com",
         "test3.com"]
    var testingFile: URL?

    override func setUp() {
        super.setUp()
        bag = DisposeBag()
        util = ContentBlockerUtility()
        relay = AppExtensionRelay.sharedInstance()
    }

    override func tearDown() {
        if testingFile != nil {
            removeFile(testingFile!)
        }
        super.tearDown()
    }

    /// Test getting filter list name
    ///
    /// This still needs to handle custom filter lists once that feature is
    /// fully implemented.
    /// See https://gitlab.com/eyeo/auxiliary/issue/issues/84.
    func testActiveFilterListName() {
        var name: String?
        setupABPState(state: .defaultFilterListEnabled)
        name = util.activeFilterListName()
        XCTAssert(name == "easylist",
                  "Default filter name is wrong.")
        setupABPState(state: .acceptableAdsEnabled)
        name = util.activeFilterListName()
        XCTAssert(name == "easylist+exceptionrules",
                  "AA filter list name is wrong.")
    }

    func testMakeWhitelistRules() {
        let domain = "test.com"
        let rule = util.makeWhitelistRule(domain: domain)
        let encoder = JSONEncoder()
        let data = try? encoder.encode(rule)
        let decoder = JSONDecoder()
        do {
            let decoded: BlockingRule =
                try decoder.decode(BlockingRule.self,
                                   from: data!)
            XCTAssert(decoded.action?.selector == nil,
                      "Bad action selector.")
            XCTAssert(decoded.action?.type == "ignore-previous-rules",
                      "Bad action type.")
            if decoded.trigger?.ifDomain != nil {
                XCTAssert(decoded.trigger?.ifDomain![0] == "*\(domain)",
                          "Bad trigger ifDomain.")
            } else {
                XCTFail("Bad trigger ifDomain.")
            }
            XCTAssert(decoded.trigger?.loadType == nil,
                      "Bad trigger loadType.")
            XCTAssert(decoded.trigger?.resourceType == nil,
                      "Bad trigger resourceType.")
            XCTAssert(decoded.trigger?.unlessDomain == nil,
                      "Bad trigger unlessDomain.")
            XCTAssert(decoded.trigger?.urlFilterIsCaseSensitive == false,
                      "Bad trigger urlFilterIsCaseSensitive.")
        } catch let error {
            XCTFail("Bad rule with error: \(error)")
        }
    }

    /// Included within are tests for the following:
    /// * test getting a blocklist on disk
    func testMergeWhitelistedWebsites() {
        let expect = expectation(description: #function)
        let ruleMax = 1 // max rules to read
        setupABPState(state: .defaultFilterListEnabled)
        guard let source = localTestFilterListRules() else {
            XCTFail("Bad rules.")
            return
        }
        var destURL: BlockListFileURL?
        util.mergedFilterListRules(from: source,
                                   with: whitelistDomains,
                                   limitRuleMaxCount: true)
            .subscribe(onNext: { fileURL in
                destURL = fileURL
            }, onError: { error in
                XCTFail("Failed with error: \(error)")
            }, onCompleted: {
                do {
                    if destURL == nil {
                        XCTFail("Bad destination URL.")
                    }
                    let data = try self.util.blocklistData(blocklist: destURL!)
                    self.ruleCount(rules: data, completion: { cnt in
                        XCTAssert(cnt == ruleMax + self.whitelistDomains.count,
                                  "Rule count is wrong.")
                    })
                } catch let error {
                    XCTFail("Failed with error: \(error)")
                }
                expect.fulfill()
            }).disposed(by: bag)
        waitForExpectations(timeout: timeout)
    }

    /// Version of merge testing that doesn't use RxSwift inside ABPKit.
    /// Included within are tests for the following:
    /// * test getting a blocklist on disk
    // swiftlint:disable function_body_length
    func testMergeWhitelistedWebsitesNonRx() {
        let expect = expectation(description: #function)
        let ruleMax = 1 // max rules to read
        let encoder = JSONEncoder()
        var rule: BlockingRule?
        let fmgr = FileManager.default
        setupABPState(state: .defaultFilterListEnabled)
        guard let rules = localTestFilterListRules() else {
            XCTFail("Bad rules.")
            return
        }
        let rulesDir = util.rulesDir(blocklist: rules)
        guard let rulesData = fmgr.contents(atPath: rules.path) // get blocklist rules
        else {
            XCTFail("Bad rules.")
            return
        }
        let decoder = JSONDecoder()
        let ruleList = try? decoder.decode(V1FilterList.self,
                                           from: rulesData)
        var cnt = 0
        let fileurl = util.makeNewBlocklistFileURL(name: "testfile",
                                                   at: rulesDir)
        testingFile = fileurl
        // swiftlint:disable unused_optional_binding
        guard let _ = try? util.startBlockListFile(blocklist: fileurl) else {
            XCTFail("Cannot make file.")
            return
        }
        // swiftlint:enable unused_optional_binding
        ruleList?.rules()
            .takeWhile({ _ in cnt < ruleMax })
            .subscribe(onNext: { rule in
                cnt += 1
                let encoder = JSONEncoder()
                guard let coded = try? encoder.encode(rule) else {
                    XCTFail("Failed to encode rule \(rule).")
                    return
                }
                self.util.writeToEndOfFile(blocklist: fileurl,
                                           with: coded)
                self.util.addRuleSeparator(blocklist: fileurl)
            }, onCompleted: {
                self.whitelistDomains.forEach {
                    rule = self.util.makeWhitelistRule(domain: $0)
                    let data = try? encoder.encode(rule)
                    self.util.writeToEndOfFile(blocklist: fileurl, with: data!)
                    self.util.addRuleSeparator(blocklist: fileurl)
                }
                self.util.endBlockListFile(blocklist: fileurl)
                do {
                    let data = try self.util.blocklistData(blocklist: fileurl)
                    self.ruleCount(rules: data, completion: { cnt in
                        XCTAssert(cnt == ruleMax + self.whitelistDomains.count,
                                  "Rule count is wrong.")
                        expect.fulfill()
                    })
                } catch let error {
                    XCTFail("Failed with error: \(error)")
                }
            }).disposed(by: bag)
        waitForExpectations(timeout: timeout)
    }
    // swiftlint:enable function_body_length

    // ------------------------------------------------------------
    // MARK: - Private -
    // ------------------------------------------------------------

    private func localTestFilterListRules() -> BlockListFileURL? {
        let bundle = Bundle(for: ContentBlockerUtilityTests.self)
        var list = FilterList()
        list.name = "v1 easylist short"
        list.fileName = "v1 easylist short.json"
        if let url = bundle.url(forResource: list.fileName!,
                                withExtension: "") {
            list.rules = url
        } else {
            XCTFail("Bad local list resource.")
        }
        // Adding a list for testing to the relay does not work because the host app loads its own lists into the relay.
        guard let rules = list.rules else {
            return nil
        }
        return rules
    }

    private func ruleCount(rules: Data,
                           completion: @escaping (Int) -> Void) {
        var cnt = 0
        let decoder = JSONDecoder()
        do {
            let ruleList = try decoder.decode(V1FilterList.self,
                                              from: rules)
            ruleList.rules()
                .subscribe(onNext: { _ in
                    cnt += 1
                },
                onError: { error in
                    XCTFail("Failed with error: \(error)")
                },
                onCompleted: {
                    completion(cnt)
                }).disposed(by: bag)
        } catch let error {
            XCTFail("Failed with error: \(error)")
        }
    }

    private enum ABPState: String {
        case defaultFilterListEnabled
        case acceptableAdsEnabled
    }

    private func setupABPState(state: ABPState) {
        relay.enabled.accept(true)
        switch state {
        case .defaultFilterListEnabled:
            relay.defaultFilterListEnabled.accept(true)
            relay.acceptableAdsEnabled.accept(false)
        case .acceptableAdsEnabled:
            relay.defaultFilterListEnabled.accept(false)
            relay.acceptableAdsEnabled.accept(true)
        }
    }

    private func removeFile(_ fileURL: URL) {
        let fmgr = FileManager.default
        // swiftlint:disable unused_optional_binding
        guard let _ = try? fmgr.removeItem(at: fileURL) else {
            XCTFail("Failed to remove testing file with file URL: \(fileURL)")
            return
        }
        // swiftlint:enable unused_optional_binding
    }
}
