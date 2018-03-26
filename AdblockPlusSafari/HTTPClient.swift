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

/// Wrapper class for making URLSessions testable with mock objects during unit testing.
class HTTPClient {
    var session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
}

typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void

/// Used for making URL sessions testable.
protocol URLSessionProtocol {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

// Default implementation.
extension URLSession: URLSessionProtocol {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request,
                         completionHandler: completionHandler) as URLSessionDataTask)
            as URLSessionDataTaskProtocol
    }
}

/// Used for making URL data tasks testable.
protocol URLSessionDataTaskProtocol {
    func resume()
    func cancel()
}

// Default implementation.
extension URLSessionDataTask: URLSessionDataTaskProtocol { }
