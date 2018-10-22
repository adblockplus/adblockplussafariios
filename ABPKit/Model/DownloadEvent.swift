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

/// Represents the changing state of a download.
public struct DownloadEvent {
    public var filterListName: FilterListName?
    public var didFinishDownloading: Bool?
    public var totalBytesWritten: Int64?
    public var error: Error?
    /// This may no longer be needed outside of the legacy implementation.
    public var errorWritten: Bool?

    public init(filterListName: FilterListName?,
                didFinishDownloading: Bool?,
                totalBytesWritten: Int64?,
                error: Error?,
                errorWritten: Bool?) {
        self.filterListName = filterListName
        self.didFinishDownloading = didFinishDownloading
        self.totalBytesWritten = totalBytesWritten
        self.error = error
        self.errorWritten = errorWritten
    }

    public init() {
        self.init(filterListName: nil,
                  didFinishDownloading: nil,
                  totalBytesWritten: nil,
                  error: nil,
                  errorWritten: nil)
    }
}
