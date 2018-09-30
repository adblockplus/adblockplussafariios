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

/// Global functions for development only.

/// Overrides definition of debugPrint to suppress debug printing in release
/// builds.
func debugPrint(items: Any...,
                separator: String = " ",
                terminator: String = "\n") {
    // The following return should never be reached.
    // It removes a compiler warning: All paths through this function will call itself.
    if items.count == -1 { return }
    #if DEBUG
        debugPrint(items: items,
                   separator: separator,
                   terminator: terminator)
    #endif
}

/// Print out all of the user's filter lists.
func debugPrintFilterLists(_ lists: [FilterList],
                           caller: String? = nil) {
    #if DEBUG
        if caller != nil {
            debugPrint("Called from \(caller!)")
        }
        debugPrint("📜 Filter Lists:")
        var cnt = 1
        for list in lists {
            debugPrint("\(cnt). \(list)\n")
            cnt += 1
        }
    #endif
}
