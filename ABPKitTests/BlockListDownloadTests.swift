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

import RxSwift
import XCTest

class BlockListDownloadTests: XCTestCase {
    let mdlr = FilterListTestModeler()
    let timeout: TimeInterval = 15
    let totalBytes = Int64(9383979)
    var bag: DisposeBag!
    var dler: BlockListDownloader!
    var filterLists = [FilterList]()
    var pstr: Persistor!
    var testList: FilterList!

    override
    func setUp() {
        super.setUp()
        bag = DisposeBag()
        dler = BlockListDownloader()
        dler.isTest = true
        pstr = Persistor()
        // swiftlint:disable unused_optional_binding
        guard let _ = try? pstr.clearFilterListModels() else {
            XCTFail("Failed to clear models.")
            return
        }
        // swiftlint:enable unused_optional_binding
        guard let list = try? mdlr.localBlockList() else {
            XCTFail("Failed to make test list.")
            return
        }
        testList = list
        guard let result = try? pstr.saveFilterListModel(testList),
              result == true
        else {
            XCTFail("Failed to save test list.")
            return
        }
    }

    func testDownloadDelegation() {
        let expect = expectation(description: #function)
        dler.blockListDownload(for: testList,
                               runInBackground: false)
            .flatMap { task -> Observable<DownloadEvent> in
                let taskID = UIBackgroundTaskIdentifier(rawValue: task.taskIdentifier)
                self.testList.taskIdentifier = taskID.rawValue
                self.testList.downloaded = true
                guard let result = try? self.pstr.saveFilterListModel(self.testList),
                      result == true
                else {
                    XCTFail("Failed to save test list.")
                    return Observable.empty()
                }
                self.setupEvents(taskID: taskID)
                guard let subj = self.dler.downloadEvents[taskID] else {
                    XCTFail("Bad publish subject.")
                    return Observable.empty()
                }
                task.resume()
                return subj.asObservable()
            }
            .subscribe(onNext: { evt in
                XCTAssert(evt.error == nil,
                          "🚨 Error during event handling: \(String(describing: evt.error?.localizedDescription)))")
                if evt.didFinishDownloading == true {
                    XCTAssert(evt.totalBytesWritten == self.totalBytes,
                              "🚨 Bytes wrong.")
                    guard let name = self.testList.name else {
                        XCTFail("Bad model name.")
                        return
                    }
                    let rulesURL = self.getRulesURL(for: name)
                    XCTAssert(rulesURL != nil,
                              "Bad rules URL.")
                }
            }, onCompleted: {
                expect.fulfill()
            }).disposed(by: bag)
        wait(for: [expect],
             timeout: timeout)
    }

    private
    func getRulesURL(for name: FilterListName) -> FilterListFileURL? {
        let util = ContentBlockerUtility()
        let tbndl = Bundle(for: type(of: self))
        if let url = try? util.getFilterListFileURL(name: name,
                                                    bundle: tbndl) {
            return url
        }
        return nil
    }

    private
    func setupEvents(taskID: UIBackgroundTaskIdentifier) {
        dler.downloadEvents[taskID] =
            BehaviorSubject<DownloadEvent>(
                value: DownloadEvent(filterListName: self.testList.name,
                                     didFinishDownloading: false,
                                     totalBytesWritten: 0,
                                     error: nil,
                                     errorWritten: false))
    }
}
