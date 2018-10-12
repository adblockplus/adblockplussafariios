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
import RxCocoa
import XCTest

class AppToExtensionStateRelayTests: XCTestCase {
    /// Test sending states through the app extension relay.
    /// Setters are in the legacy app. Changes are picked up by RxSwift KVO.
    /// * acceptableAdsEnabled
    /// * defaultFilterListEnabled
    /// * downloadedVersion
    /// * enabled
    /// * installedVersion
    /// * lastActivity
    /// * whitelistedWebsites
    func testSendingStates() {
        let abp = AdblockPlus()
        let relay = ABPKit.AppExtensionRelay.sharedInstance()
        let testDate = Date()
        let timeFactor: TimeInterval = Constants.defaultFilterListExpiration
        let testWebsiteHost = "adblockplus.org"
        for idx in 0...10 {
            var state = false
            if Int(arc4random_uniform(2)) == 1 { state = true }
            abp.acceptableAdsEnabled = state
            abp.defaultFilterListEnabled = state
            abp.downloadedVersion = idx
            abp.enabled = state
            abp.installedVersion = idx
            abp.lastActivity = testDate + TimeInterval(idx) * timeFactor
            abp.whitelistedWebsites = [testWebsiteHost] + [String(idx)]
            XCTAssertTrue(relay.acceptableAdsEnabled.value == state,
                          "Mismatched state: expected \(state) but got \(String(describing: relay.acceptableAdsEnabled.value))")
            XCTAssertTrue(relay.defaultFilterListEnabled.value == state,
                          "Mismatched state: expected \(state) but got \(String(describing: relay.defaultFilterListEnabled.value))")
            XCTAssertTrue(relay.downloadedVersion.value == idx,
                          "Mismatched state: expected \(idx) but got \(String(describing: relay.downloadedVersion.value))")
            XCTAssertTrue(relay.enabled.value == state,
                          "Mismatched state: expected \(state) but got \(String(describing: relay.enabled.value))")
            XCTAssertTrue(relay.installedVersion.value == idx,
                          "Mismatched state: expected \(idx) but got \(String(describing: relay.installedVersion.value))")
            let expectedDate = testDate + TimeInterval(idx) * timeFactor
            XCTAssertTrue(relay.lastActivity.value == expectedDate,
                          "Mismatched state: expected \(expectedDate) but got \(String(describing: relay.lastActivity.value))")
            let expectedHosts = [testWebsiteHost] + [String(idx)]
            XCTAssertTrue(relay.whitelistedWebsites.value == expectedHosts,
                          "Mismatched state: expected \(expectedHosts) but got \(String(describing: relay.whitelistedWebsites.value))")
        }
    }
}
