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

@testable import libadblockplus_ios
import XCTest

class ParsingTests: XCTestCase {
    /// Expected number of test rules.
    let testingRuleCount = 7
    var localPath: String!
    var v1FileURL: URL!
    var v2FileURL: URL!

    override func setUp() {
        super.setUp()
        // Load test filter lists.
        let testingBundle = Bundle(for: type(of: self))
        localPath =
            testingBundle.path(forResource: "v1 easylist short",
                               ofType: "json")
        guard let v1path = localPath else {
            XCTAssert(false, "V1 filter list missing")
            return
        }
        v1FileURL = URL(fileURLWithPath: v1path)
        localPath =
            testingBundle.path(forResource: "v2 easylist short",
                               ofType: "json")
        guard let v2path = localPath else {
            XCTAssert(false, "V2 filter list missing")
            return
        }
        v2FileURL = URL(fileURLWithPath: v2path)
    }

    /// Test parsing v1 filter lists.
    func testParsingV1FilterList() {
        guard let url = v1FileURL else {
            XCTFail("Missing url")
            return
        }
        let decoder = JSONDecoder()
        do {
            if let data = try? filterListData(url: url) {
                let list = try decoder.decode(V1FilterList.self,
                                              from: data)
                XCTAssert(list.rules.count == testingRuleCount,
                          "Wrong rule count")
            }
        } catch let error {
            XCTFail("Decode failed with error: \(error)")
        }
    }

    /// Test parsing v2 filter lists.
    func testParsingV2FilterList() {
        guard let url = v2FileURL else {
            XCTFail("Missing url")
            return
        }
        let decoder = JSONDecoder()
        do {
            if let data = try? filterListData(url: url) {
                let list = try decoder.decode(V2FilterList.self,
                                              from: data)
                XCTAssert(list.rules.count == testingRuleCount,
                          "Wrong rule count")
            }
        } catch let error {
            XCTFail("Decode failed with error: \(error)")
        }
    }

    /// Get filter lister data.
    /// - parameter url: File URL of the data
    /// - returns: Data of the filter list
    /// - throws: ABPKitTestingError
    func filterListData(url: URL) throws -> Data {
        guard let data = try? Data(contentsOf: url,
                                   options: .uncached)
        else {
            XCTFail("Invalid data")
            throw ABPKitTestingError.invalidData
        }
        return data
    }
}
