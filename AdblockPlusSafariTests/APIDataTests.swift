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

class APIDataTests: XCTestCase {
    func testAPIData() {
        let endpoint = ABPAPIData.endpointReceiveDeviceData()
        if endpoint != nil {
            XCTAssert(URL(string: endpoint!) != nil,
                      "Endpoint should be a valid URL")
        }
        let key = ABPAPIData.keyAPIReceiveDeviceData()
        if key != nil {
            XCTAssert(invalidCharCnt(str: key!) == 0,
                      "API key should only have letters or digits")
        }
    }

    private func invalidCharCnt(str: String) -> Int {
        let letters = CharacterSet.letters
        let digits = CharacterSet.decimalDigits
        return str.unicodeScalars.map {
            if letters.contains($0) || digits.contains($0) {
                return 0
            }
            return 1
        }.reduce(0, +)
    }
}
