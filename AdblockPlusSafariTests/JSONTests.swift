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

@testable import AdblockPlusSafari

import ABPKit
import XCTest

/// Test JSON operations.
class JSONTests: XCTestCase {
    var localPath: String!
    var localURL: URL!

    override func setUp() {
        super.setUp()
        let testBundle = Bundle(for: type(of: self))
        localPath = testBundle.path(forResource: "easylist_content_blocker_v2_short",
                                    ofType: "json")
        guard let path = localPath else {
            XCTAssert(false, "Filter list missing")
            return
        }
        localURL = URL(fileURLWithPath: path)
    }

    override func tearDown() {
        super.tearDown()
    }

    /// Test parsing version from a v2 filter list.
    func testParseVersion() {
        var data: Data?
        do {
            data = try Data(contentsOf: localURL,
                            options: .uncached)
        } catch let error {
            XCTAssert(false, "Error with data: \(error)")
            return
        }
        guard let uwData = data else {
            XCTAssert(false, "Data missing")
            return
        }
        let json = ABPKit.V2FilterList(with: uwData)
        XCTAssert(json?.version == "201512011207", "Parsed version value is wrong")
    }

    /// Test setting the version on a filter list after parsing it.
    func testSetVersion() {
        let mgr = ABPManager.sharedInstance()
        let updater = mgr.filterListsUpdater
        var list = ABPKit.FilterList()
        do {
            try updater?.setVersion(url: localURL,
                                    filterList: &list)
        } catch let error {
            XCTAssert(false, "Error with set version: \(error)")
            return
        }
        XCTAssert(list.version == "201512011207", "Set version value is wrong")
    }
}
