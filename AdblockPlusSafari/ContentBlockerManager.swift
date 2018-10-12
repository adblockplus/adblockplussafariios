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

import ABPKit

/// Performs reload operations with the Safari content blocker manager for a
/// given identifier.
class ContentBlockerManager: NSObject,
                             ContentBlockerManagerProtocol {
    func reload(withIdentifier identifier: String,
                completionHandler: ((Error?) -> Void)? = nil) {
        let mgr = ABPManager.sharedInstance()
        let reloading = { value in mgr.adblockPlus.reloading = value }
        let performingActivityTest = { value in mgr.adblockPlus.performingActivityTest = value }
        let scb = SafariContentBlocker(reloadingSetter: reloading,
                                       performingActivityTestSetter: performingActivityTest)
        scb.reloadContentBlocker(completion: completionHandler)
    }
}
