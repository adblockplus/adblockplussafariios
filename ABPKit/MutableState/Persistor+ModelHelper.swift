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

// Helper operations for filter lists models in persistence storage:
// * save
// * load
// * clear
extension Persistor {
    /// Return true if save succeeded.
    func saveFilterListModel(_ list: FilterList) throws -> Bool {
        guard let saved = try? loadFilterListModels() else {
            return false
        }
        let lists = saved
        let newLists =
            replaceFilterListModel(list,
                                   lists: lists)
        guard let data =
            try? PropertyListEncoder()
                .encode(newLists) else {
            throw ABPFilterListError.failedEncoding
        }
        // swiftlint:disable unused_optional_binding
        guard let _ =
            try? save(type: Data.self,
                      value: data,
                      key: ABPMutableState.LegacyStateName.filterLists)
        else {
            return false
        }
        // swiftlint:enable unused_optional_binding
        return true
    }

    func loadFilterListModels() throws -> [FilterList] {
        guard let data =
            try? load(type: Data.self,
                      key: ABPMutableState.LegacyStateName.filterLists)
        else {
            return []
        }
        guard let decoded = try? decodeListsModelsData(data) else {
            throw ABPFilterListError.failedDecoding
        }
        return decoded
    }

    func clearFilterListModels() throws {
        // swiftlint:disable unused_optional_binding
        guard let _ = try? clear(key: ABPMutableState.LegacyStateName.filterLists)
        else {
            throw ABPMutableStateError.failedClear
        }
        // swiftlint:enable unused_optional_binding
    }

    private
    func decodeListsModelsData(_ listsData: Data) throws -> [FilterList] {
        guard let decoded =
            try? PropertyListDecoder()
                .decode([FilterList].self,
                        from: listsData)
        else {
            throw ABPFilterListError.badData
        }
        return decoded
    }

    private
    func replaceFilterListModel(_ list: FilterList,
                                lists: [FilterList]) -> [FilterList] {
        var newLists = [FilterList]()
        var replaceCount = 0
        lists.forEach {
            if $0.name == list.name {
                newLists.append(list)
                replaceCount += 1
            } else {
                newLists.append(list)
            }
        }
        if replaceCount < 1 {
            newLists.append(list)
        }
        return newLists
    }
}
