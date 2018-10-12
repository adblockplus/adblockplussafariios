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

/// Data sent during downloads of filter lists.
public struct FilterListDownloadData {
    let addonName = "adblockplusios",
        addonVer = ABPActiveVersions.appVersion() ?? "",
        application = "safari",
        applicationVer = ABPActiveVersions.iosVersion(),
        platform = "webkit",
        platformVer = ABPActiveVersions.webkitVersion() ?? ""

    /// Maximum value beyond which download count is represented by (n-1)+.
    let maxDownloadCount = 5

    public var queryItems: [URLQueryItem]!

    /// Construct a filter list download data struct.
    /// - Parameter filterList: The local filter list corresponding to the download data.
    public init(with filterList: FilterList) {
        queryItems = [URLQueryItem(name: "addonName",
                                   value: addonName),
            URLQueryItem(name: "addonVersion",
                         value: addonVer),
            URLQueryItem(name: "application",
                         value: application),
            URLQueryItem(name: "applicationVersion",
                         value: applicationVer),
            URLQueryItem(name: "platform",
                         value: platform),
            URLQueryItem(name: "platformVersion",
                         value: platformVer),
            URLQueryItem(name: "lastVersion",
                         value: filterList.lastVersion),
            URLQueryItem(name: "downloadCount",
                         value: downloadCountString(for: filterList))]
    }
}

extension FilterListDownloadData {
    func downloadCountString(for filterList: FilterList) -> String {
        if let count = filterList.downloadCount {
            if count >= maxDownloadCount {
                return String(maxDownloadCount - 1) + "+"
            } else {
                return String(count)
            }
        }
        return "0"
    }
}
