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

/// Contains functions specific to interoperating with Objective-C.
extension ABPManager {
    /// During the transition to Swift, filter lists previously held in Objective-C data structures
    /// will be made available in native Swift.
    func filterLists() -> [FilterList] {
        var result = [FilterList]()
        for key in adblockPlus.filterLists.keys {
            let converted = FilterList(withName: key,
                                       fromDictionary: adblockPlus.filterLists[key])
            result.append(converted!)
        }
        return result
    }

    /// Write the filter lists back to Objective-C.
    /// It is to be called with the lists to be saved.
    func saveFilterLists(_ lists: [FilterList]) {
        var converted = [String: [String: Any]]()
        for list in lists {
            if let name = list.name {
                converted[name] = list.toDictionary()
            }
        }
        adblockPlus.filterLists = converted
    }

    /// Remove a filter list and save the results to the Objective-C side.
    func removeFilterList(_ name: String?) {
        guard name != nil else { return }
        saveFilterLists(filterLists().filter { $0.name != name })
    }

    /// Set updating on all filter lists to be false.
    func setNotUpdating(forNames names: [FilterListName]) {
        let lists = filterLists()
        var newLists = [FilterList]()
        for var list in lists {
            list.updating = false
            newLists.append(list)
        }
        saveFilterLists(newLists)
    }
}
