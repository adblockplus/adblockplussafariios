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

// Functions related to the legacy implementation.
extension FilterListsUpdater {
    /// Maintain compatibility with the legacy implementation by writing data to the Objective-C side.
    /// - Parameters:
    ///   - filterList: A filter list.
    ///   - task: A download task if available.
    ///   - userTriggered: User triggered flag.
    /// - Throws: Error if data is invalid.
    func internallyUpdate(with update: FilterListUpdate) throws {
        guard let name = update.filterList.name else {
            throw ABPFilterListError.invalidData
        }
        setLegacySetFilterListsUpdated()
        var newFilterList = update.filterList
        newFilterList.taskIdentifier = update.task.taskIdentifier
        newFilterList.updating = false
        newFilterList.updatingGroupIdentifier = self.updatingGroupIdentifier
        newFilterList.userTriggered = update.userTriggered
        newFilterList.lastUpdateFailed = false
        newFilterList.lastUpdate = update.filterList.lastUpdate
        updateSuccessfulDownloadCount(for: &newFilterList)
        // Write the filter list back to the Objective-C side.
        replaceFilterList(withName: name,
                          withNewList: newFilterList)
    }

    /// Sets a flag used only during onboarding. It is used to manage the state of the UI.
    /// This usage will be removed in future updates.
    private func setLegacySetFilterListsUpdated() {
        let onboardingKey = "FilterListsUpdated"
        let defaults = UserDefaults.standard
        defaults.set(true,
                     forKey: onboardingKey)
        defaults.synchronize()
    }
}
