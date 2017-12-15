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

/// Objective-C bridging for FilterList model struct.
extension FilterList {
    /// Failable initializer that converts a filter list object from the Objective-C implementation.
    init?(fromDictionary dictionary: [String: Any]?) {
        guard let uwDict = dictionary else { return nil }
        taskIdentifier = uwDict["taskIdentifier"] as? UInt16
        updatingGroupIdentifier = uwDict["updatingGroupIdentifier"] as? UInt16
        downloaded = uwDict["downloaded"] as? Bool
        expires = uwDict["expires"] as? TimeInterval
        fileName = uwDict["fileName"] as? String
        lastUpdate = uwDict["lastUpdate"] as? Date
        lastUpdateFailed = uwDict["lastUpdateFailed"] as? Bool
        updating = uwDict["updating"] as? Bool
        url = uwDict["url"] as? String
        userTriggered = uwDict["userTriggered"] as? Bool
        version = uwDict["version"] as? String
    }

    /// Create a dictionary suitable for use with Objective-C.
    func toDictionary() -> [String: Any]? {
        var dict = [String: Any]()
        dict["taskIdentifier"] = taskIdentifier
        dict["updatingGroupIdentifier"] = updatingGroupIdentifier
        dict["downloaded"] = downloaded
        dict["expires"] = expires
        dict["fileName"] = fileName
        dict["lastUpdate"] = lastUpdate
        dict["lastUpdateFailed"] = lastUpdateFailed
        dict["updating"] = updating
        dict["url"] = url
        dict["userTriggered"] = userTriggered
        dict["version"] = version
        return dict
    }
}
