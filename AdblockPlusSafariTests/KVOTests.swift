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
import XCTest

/// Test KVO operations.
class KVOTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // ------------------------------------------------------------
    // MARK: - Observer tests -
    // ------------------------------------------------------------

    /// Test if the reloading observer is active.
    func testReloadingObserverIsActive() {
        let mgr = ABPManager.sharedInstance()
        let abp = mgr.adblockPlus
        let testValues: [Int] = Array(0...10).map { _ in
            if arc4random_uniform(2) == 1 { return 1 }
            return 0
        }
        _ = testValues.map {
            abp?.reloading = ($0 == 1)
            XCTAssert(mgr.reloadingKeyValue == $0, "Reloading key value is wrong")
        }
    }

    /// Test if the filterLists observer is active.
    /// Default filter lists should be set if none are stored in defaults.
    func testFilterListsObserverIsActive() {
        let mgr = ABPManager.sharedInstance()
        let abp = mgr.adblockPlus
        XCTAssert((abp?.filterLists.keys.count ?? 0) > 0, "Default filter lists were not set")
    }
}
