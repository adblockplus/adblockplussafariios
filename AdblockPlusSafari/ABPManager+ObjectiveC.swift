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

import libadblockplus_ios

/// Contains functions specific to interoperating with Objective-C.
extension ABPManager {
    /// During the transition to Swift, filter lists stored as Objective-C model objects will be
    /// converted to Swift model structs. If a filter list cannot be converted, it will not be
    /// visible to Swift.
    func filterLists() -> [libadblockplus_ios.FilterList] {
        var result = [libadblockplus_ios.FilterList]()
        for key in adblockPlus.filterLists.keys {
            let converted = FilterList(named: key,
                                       fromDictionary: adblockPlus.filterLists[key])
            if converted != nil {
                result.append(converted!)
            }
        }
        return result
    }

    /// Write the filter lists back to Objective-C.
    /// - Parameter lists: The lists to be saved.
    func saveFilterLists(_ lists: [libadblockplus_ios.FilterList]) {
        var converted = [String: [String: Any]]()
        for list in lists {
            if let name = list.name {
                converted[name] = list.toDictionary()
            }
        }
        DispatchQueue.main.async {
            self.adblockPlus.filterLists = converted
        }
    }

    /// Remove a filter list and save the results to the Objective-C side.
    func removeFilterList(_ name: String?) {
        guard name != nil else { return }
        saveFilterLists(filterLists().filter { $0.name != name })
    }

    /// Set updating on all filter lists to be false.
    func setNotUpdating(forNames names: [FilterListName]) {
        let lists = filterLists()
        var newLists = [libadblockplus_ios.FilterList]()
        for var list in lists {
            list.updating = false
            newLists.append(list)
        }
        saveFilterLists(newLists)
    }
}
