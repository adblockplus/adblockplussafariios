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

public
struct ABPMutableState {
    /// Enum is named legacy to indicate source of cases.
    public
    enum LegacyStateName: String,
                          CaseIterable {
        case empty
        case acceptableAdsEnabled
        case customFilterListEnabled
        case defaultFilterListEnabled
        case downloadedVersion
        case enabled
        case filterLists
        case group
        case installedVersion
        case lastActivity
        case shouldRespondToActivityTest
        case whitelistedWebsites
    }

    public var acceptableAdsEnabled: Bool?
    public var customFilterListEnabled: Bool?
    public var defaultFilterListEnabled: Bool?
    public var downloadedVersion: Int?
    public var enabled: Bool?
    public var filterLists: [FilterList]?
    public var group: String?
    public var installedVersion: Int?
    public var lastActivity: Date?
    public var shouldRespondToActivityTest: Bool?
    public var whitelistedWebsites: [WhitelistedHostname]?

    init() {
        // Intentionally empty
    }
}
