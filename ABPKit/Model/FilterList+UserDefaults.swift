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

 extension FilterList {
    /// Construct a new filter list matching one saved in the legacy adblockPlusDetails user
    /// defaults.
    /// - Parameter name: The name of the existing filter list.
    public init?(matching name: FilterListName,
                 root: [String: Any]?) {
        let listDict = root?[name] as? [String: Any]
        guard let filterList = FilterList(named: name,
                                          fromDictionary: listDict)
        else {
            return nil
        }
        self = filterList
    }
}
