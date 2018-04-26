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

import libadblockplus_ios
import RxSwift

extension FilterListsUpdater {
    /// Updates the user's active filter list if it is expired.
    /// - Returns: True if the filter list needs to be updated, false otherwise.
    func expiredFilterListUpdate() -> Observable<Bool> {
        return Observable.create { observer in
            let updater = ABPManager.sharedInstance().filterListsUpdater
            guard let activeName = updater?.activeFilterListName() else {
                observer.onError(ABPFilterListError.invalidData)
                return Disposables.create()
            }
            let activeList = ABPManager.sharedInstance().adblockPlus.filterLists[activeName]
            let filterList = FilterList(named: activeName,
                                        fromDictionary: activeList)
            if filterList?.expired() == true {
                self.updateFilterLists(withNames: [activeName],
                                       userTriggered: false,
                                       completion: { _ in
                    observer.onNext(true)
                    observer.onCompleted()
                })
            } else {
                observer.onNext(false)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
