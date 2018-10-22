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

@testable import ABPKit

import Foundation

class FilterListTestModeler: NSObject {
    let testFilename = "test_easylist_content_blocker.json"
    let testVersion = "20181020"
    var bundle: Bundle!
    var pstr: Persistor!

    override
    init() {
        super.init()
        bundle = Bundle(for: type(of: self))
        pstr = Persistor()
    }

    /// This model object is for testing the delegate with local data.
    func localBlockList() throws -> FilterList {
        var list = FilterList()
        let localSource: () -> URL? = {
            guard let url =
                self.bundle
                    .url(forResource: self.testFilename,
                         withExtension: "")
            else {
                return nil
            }
            return url
        }
        guard let src = localSource() else {
            throw ABPKitTestingError.invalidData
        }
        list.source = src.absoluteString
        list.lastVersion = testVersion
        list.name = UUID().uuidString
        list.fileName = testFilename
        return list
    }

    /// Save a given number of test lists to local storage.
    func populateTestModels(count: Int) throws {
        for _ in 1...count {
            guard let testList = try? localBlockList() else {
                throw ABPKitTestingError.failedModelCreation
            }
            let result = try? pstr.saveFilterListModel(testList)
            if result != true {
                throw ABPKitTestingError.failedSave
            }
        }
    }
}
