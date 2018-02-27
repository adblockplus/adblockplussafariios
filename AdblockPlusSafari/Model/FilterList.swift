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

/// Swift-based FilterList model struct to replace the Objective-C FilterList model object. This
/// is used internally to represent filter lists.
struct FilterList {
    /// Counter for number of downloads.
    var downloadCount: Int?

    /// Name used to identify a list uniquely.
    var name: FilterListName?

    /// The last version value extracted from the filter list.
    var lastVersion: FilterListLastVersion?

    /// Task identifier of the associated download task.
    var taskIdentifier: Int?

    /// Group identifier refer to an associated download group. Only download tasks triggered by a
    /// user are allowed to display download failure dialogs. The updatingGroupIdentifier
    /// represents the group of the most recent download tasks.
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

extension FilterList {
    /// This is not using an expiration interval from a v2 filter list as that data is not yet available.
    /// - Returns: True if the filter list is considered to be expired.
    func expired() -> Bool {
        let nowInterval = Date.timeIntervalSinceReferenceDate
        if expires == nil && lastUpdate != nil {
            // Default to a fixed expiration.
            let defaultIntervalPlusLast = lastUpdate!.addingTimeInterval(GlobalConstants.defaultFilterListExpiration)
                                                     .timeIntervalSinceReferenceDate
            return defaultIntervalPlusLast < nowInterval
        } else if expires != nil && lastUpdate != nil {
            return expires! < nowInterval
        } else {
            // Expires is nil and last update is nil.
            return true
        }
    }
}
