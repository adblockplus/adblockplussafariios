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

class RuleCountTests: XCTestCase {
    var bag = DisposeBag()
    let timeout: TimeInterval = 8
    /// Value is rule count.
    let testLists = ["v1 easylist short": 7,
                     "v2 easylist short": 7,
                     "v2 easylist short partial": 0,
                     "test_easylist_content_blocker": 45899]

    func testRuleCounting() {
        let expect = expectation(description: #function)
        var list = FilterList()
        testLists.forEach { key, _ in
            let util = TestingFileUtility()
            list.rules =
                util.fileURL(resource: key,
                             ext: "json")
            list.ruleCount().subscribe(onNext: { cnt in
                XCTAssert(cnt == self.testLists[key],
                          "Rule count of \(cnt) doesn't match \(String(describing: self.testLists[key])) for \(key)")
            }).disposed(by: bag)
        }
        expect.fulfill()
        wait(for: [expect],
             timeout: timeout,
             enforceOrder: true)
    }
}
