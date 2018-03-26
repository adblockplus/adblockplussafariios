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

/// Globally available constants used for configuration.
struct GlobalConstants {
    /// Time limit for background operations. It is less than the allowed limit to allow time for
    /// content blocker reloading.
    static let backgroundOperationLimit: TimeInterval = 28

    /// Time limit for foreground operations.
    static let foregroundOperationLimit: TimeInterval = 10 * backgroundOperationLimit

    /// The number of times to try an immediate reload if an error is encountered.
    static let contentBlockerReloadRetryCount = 3

    /// Default interval for expiration of a filter list.
    static let defaultFilterListExpiration: TimeInterval = 86400

    /// Maximum favicon size to download.
    static let faviconSize = 180

    /// Token save timeout.
    static let tokenSaveTimeout: TimeInterval = 30
}
