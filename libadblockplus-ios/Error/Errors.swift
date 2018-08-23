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
public enum ABPDownloadTaskError: Error {
    case failedToMakeDownloadTask
    case tooManyRequests
}

/// Error cases for filter list processing.
/// - badContainer: Container could not be accessed.
/// - failedDecode: Could not decode data.
/// - invalidData: Data could not be read from the list.
/// - missingName: Name could not be read.
/// - notFound: Count not find a matching filter list.
public enum ABPFilterListError: Error {
    case badContainer
    case failedDecode
    case invalidData
    case missingName
    case notFound
}

/// Error cases for managing device tokens.
/// - invalidEndpoint: Endpoint URL was not found.
public enum ABPDeviceTokenSaveError: Error {
    case invalidEndpoint
}

/// Error cases for managing content blocking.
/// - invalidAppGroup: Invalid app group.
/// - invalidFilterListAttachment: Filter list attachment is invalid.
/// - invalidIdentifier: Invalid ID.
public enum ABPContentBlockerError: Error {
    case invalidAppGroup
    case invalidFilterListAttachment
    case invalidIdentifier
}
