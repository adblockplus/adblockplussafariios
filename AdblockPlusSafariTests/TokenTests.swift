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

@testable import AdblockPlusSafari
import RxCocoa
import RxSwift
import RxSwiftExt
import XCTest

class MockURLSession: URLSessionProtocol {
    /// Max retry count.
    let maxCount = 10

    /// Test should be allowed to succeed after this count.
    var succeedAfterCount = 5

    /// Current request count.
    var requestCount = 0

    let dummyURL = URL(string: "https://127.0.0.1")
    let statusSuccess = 200
    let statusFail = 429
    var shouldFail = BehaviorRelay<Bool>(value: true)

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        var statusCode = 0
        var error: ABPDownloadTaskError?
        requestCount += 1
        if requestCount > succeedAfterCount {
            shouldFail.accept(false)
        }
        if shouldFail.value {
            statusCode = statusFail
            error = .tooManyRequests
        } else {
            statusCode = statusSuccess
        }
        completionHandler(nil,
                          makeResponse(statusCode: statusCode),
                          error)
        return MockURLSessionDataTask()
    }

    /// Generate a dummy response.
    func makeResponse(statusCode: Int) -> URLResponse? {
        if let url = dummyURL {
            return HTTPURLResponse(url: url,
                                   statusCode: statusCode,
                                   httpVersion: nil,
                                   headerFields: nil)
        }
        return nil
    }
}

/// Empty implementations are needed to override the default behavior.
class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    func resume() { }
    func cancel() { }
}

class DeviceTokenTests: XCTestCase {
    var testToken: String = "TEST_TOKEN"
    var bag: DisposeBag! = DisposeBag()
    var mockSession = MockURLSession()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// Test saving a token where the request fails for a few iterations initially with a 429 too many
    /// requests error.
    func testTokenSave() {
        let maxRetryCount: UInt = 10
        let retryDelay: Double = 1
        let expect = expectation(description: #function)
        let timeout = 20.0
        let appDel = AppDelegate()
        appDel.httpClient = HTTPClient(session: mockSession)
        guard let client = appDel.httpClient else {
            XCTFail("Invalid client")
            return
        }
        appDel.deviceTokenSave(token: testToken,
                               client: client)
            .retry(.delayed(maxCount: maxRetryCount,
                            time: retryDelay))
            .subscribe(onNext: {
                XCTAssert($0 == self.testToken, "Test token was not received")
            }, onError: { err in
                XCTAssert(self.mockSession.shouldFail.value == true &&
                          err as? ABPDownloadTaskError == .tooManyRequests,
                          "Error was expected")
                expect.fulfill()
            }, onCompleted: {
                appDel.httpClient = nil
                expect.fulfill()
            }).disposed(by: bag)
        wait(for: [expect],
             timeout: timeout)
    }
}
