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

/// Swift-based FilterList model struct to replace the Objective-C FilterList model object.
struct FilterList {
    /// Name of the list
    var name: String?

    /// Task identifier of associated download task
    var taskIdentifier: Int?

    /// Group identifier refer to an associated download group.
    /// Only download tasks triggered by a user are allowed to display download failure dialogs.
    /// updatingGroupIdentifier represents the most recent download tasks.
    var updatingGroupIdentifier: Int?

    var downloaded: Bool?
    var expires: TimeInterval?
    var fileName: String?
    var lastUpdate: Date?
    var lastUpdateFailed: Bool?
    var updating: Bool?
    var url: String?
    var userTriggered: Bool?
    var version: String?
}

extension FilterList
{
    /// Return true if filter list has expired based on last update + expires interval.
    func expired() -> Bool
    {
        guard let uwLastUpdate = lastUpdate,
            let uwExpires = expires else
        {
            return false
        }
        let lastUpdateInterval = uwLastUpdate.timeIntervalSinceReferenceDate
        return lastUpdateInterval + uwExpires < Date.timeIntervalSinceReferenceDate
    }
}
