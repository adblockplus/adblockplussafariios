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

// Objective-C bridging for FilterList model struct.
extension FilterList {
    /// Returns URL for rules without parsing them.
    func getRulesURL(for name: FilterListName) -> FilterListFileURL? {
        let util = ContentBlockerUtility()
        if let url = try? util.getFilterListFileURL(name: name) {
            return url
        }
        return nil
    }

    /// Failable initializer that converts a filter list object from the Objective-C
    /// implementation.
    /// - parameters:
    ///   - name: Unique name for the filter list.
    ///   - dictionary: NSDictionary from legacy data model.
    public init?(named name: String,
                 fromDictionary dictionary: [String: Any]?) {
        guard let uwDict = dictionary else { return nil }
        self.name = name
        taskIdentifier = uwDict["taskIdentifier"] as? Int
        updatingGroupIdentifier = uwDict["updatingGroupIdentifier"] as? Int
        downloaded = uwDict["downloaded"] as? Bool
        expires = uwDict["expires"] as? TimeInterval
        fileName = uwDict["fileName"] as? String
        lastUpdate = uwDict["lastUpdate"] as? Date
        lastUpdateFailed = uwDict["lastUpdateFailed"] as? Bool
        updating = uwDict["updating"] as? Bool
        source = uwDict["url"] as? String
        userTriggered = uwDict["userTriggered"] as? Bool
        version = uwDict["version"] as? String
        self.downloadCount = uwDict["downloadCount"] as? Int
        rules = nil // default value that prevents a build error
        rules = getRulesURL(for: name)
    }

    /// - Returns: A dictionary suitable for use with Objective-C.
    public func toDictionary() -> [String: Any]? {
        var dict = [String: Any]()
        dict["taskIdentifier"] = taskIdentifier
        dict["updatingGroupIdentifier"] = updatingGroupIdentifier
        dict["downloaded"] = downloaded
        dict["expires"] = expires
        dict["fileName"] = fileName
        dict["lastUpdate"] = lastUpdate
        dict["lastUpdateFailed"] = lastUpdateFailed
        dict["updating"] = updating
        dict["url"] = source
        dict["userTriggered"] = userTriggered
        dict["version"] = version
        dict["downloadCount"] = downloadCount
        return dict
    }
}
