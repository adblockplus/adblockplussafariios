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

/// Custom errors for ABP.

/// Error cases for download tasks.
/// - failedToMakeDownloadTask: Download task could not be created for the download.
/// - tooManyRequests: HTTP connection failed due to temporary state.
enum ABPDownloadTaskError: Error {
    case failedToMakeDownloadTask
    case tooManyRequests
}

/// Error cases for filter list processing.
/// - invalidData: Data could not be read from the list.
enum ABPFilterListError: Error {
    case invalidData
}

/// Error cases for managing device tokens.
/// - invalidEndpoint: Endpoint URL was not found.
enum ABPDeviceTokenSaveError: Error {
    case invalidEndpoint
    case invalidClient
}
