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

/// Error cases for configuration.
/// - invalidBundlePrefix: Bundle prefix is not valid.
public
enum ABPConfigurationError: Error {
    case invalidBundlePrefix
}

/// Error cases for download tasks.
/// - badAppGroup: App group was not obtained successfully.
/// - badFilename: Bad filename for filter list rules.
/// - badFilterListModel: Bad model object.
/// - badFilterListModelName: Bad name for model object.
/// - failedFilterListModelSave: Failed to save model object.
/// - failedToMakeBackgroundSession: Failed during background session creation.
/// - failedToMakeDownloadTask: Download task could not be created for the download.
/// - invalidResponse: Web server response was invalid.
/// - tooManyRequests: HTTP connection failed due to temporary state.
public
enum ABPDownloadTaskError: Error {
    case badAppGroup
    case badFilename
    case badFilterListModel
    case badFilterListModelName
    case failedFilterListModelSave
    case failedToMakeBackgroundSession
    case failedToMakeDownloadTask
    case invalidResponse
    case tooManyRequests
}

/// Error cases for filter list processing.
/// - ambiguousModels: Model objects are not unique or are missing.
/// - badContainer: Container could not be accessed.
/// - badData: Valid data was not obtained.
/// - failedDecoding: Could not decode a list.
/// - failedEncodeRule: A rule could not be encoded.
/// - failedEncoding: A list model could not be encoded.
/// - failedFileCreation: Could not make a file.
/// - failedLoadModels: Could not load models.
/// - invalidData: Data could not be read from the list.
/// - missingName: Name could not be read.
/// - missingRules: Rules could not be read.
/// - notFound: Count not find a matching filter list.
public
enum ABPFilterListError: Error {
    case ambiguousModels
    case badContainer
    case badData
    case failedDecoding
    case failedEncodeRule
    case failedEncoding
    case failedFileCreation
    case failedLoadModels
    case invalidData
    case missingName
    case missingRules
    case notFound
}

/// Error cases for managing device tokens.
/// - invalidEndpoint: Endpoint URL was not found.
public
enum ABPDeviceTokenSaveError: Error {
    case invalidEndpoint
}

/// Error cases for managing content blocking.
/// - invalidAppGroup: Invalid app group.
/// - invalidFilterListAttachment: Filter list attachment is invalid.
/// - invalidFilterListName: Filter list name is invalid.
/// - invalidIdentifier: Invalid ID.
public
enum ABPContentBlockerError: Error {
    case invalidAppGroup
    case invalidFilterListAttachment
    case invalidFilterListName
    case invalidIdentifier
}

/// Error cases related to mutable state.
/// - invalidData: Indicates error with data.
/// - invalidType: Indicates error with a type.
/// - missingDefaults: UserDefaults not found.
/// - missingsDefaultsSuiteName: Suite name not found.
public
enum ABPMutableStateError: Error {
    case failedClear
    case invalidData
    case invalidType
    case missingDefaults
    case missingsDefaultsSuiteName
}
