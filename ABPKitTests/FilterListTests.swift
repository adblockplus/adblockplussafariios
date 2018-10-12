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

import XCTest

class FilterListTests: XCTestCase {
    /// Test expired logic.
    func testExpired() {
        var filterList = ABPKit.FilterList()
        filterList.lastUpdate = Date()
        XCTAssert(!filterList.expired(),
                  "Last update is now - should not be expired")
        filterList.lastUpdate = Date() - Constants.defaultFilterListExpiration - 1
        XCTAssert(filterList.expired(),
                  "Last updated is beyond default expiration - should be expired")
        filterList.lastUpdate = Date() - Constants.defaultFilterListExpiration + 1
        XCTAssert(!filterList.expired(),
                  "Last updated is not beyond default expiration - should not be expired")
        filterList.expires = Date().timeIntervalSinceReferenceDate - 1
        XCTAssert(filterList.expired(),
                  "Expires < now - should be expired")
    }
}
