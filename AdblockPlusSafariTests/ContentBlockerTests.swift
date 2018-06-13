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
import libadblockplus_ios
import XCTest

/// Test content blocker operations.
class ContentBlockerTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// * Test reloading of content blocker.
    /// * Test detection of content blocker activation or enabled state.
    func testReloadContentBlocker() {
        let expect = expectation(description: "Expectations for reloader")
        let timeout = 20.0
        let mgr = ABPManager.sharedInstance()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2,
                                      execute: {
            mgr.filterListsUpdater?.safariCB.reloadContentBlocker(completion: { error in
                XCTAssert(mgr.adblockPlus.activated, "Content blocker has not been enabled")
                XCTAssert(error == nil,
                          "Error during reload: \(String(describing: error))")
                expect.fulfill()
            })
        })
        wait(for: [expect],
             timeout: timeout)
    }
}
