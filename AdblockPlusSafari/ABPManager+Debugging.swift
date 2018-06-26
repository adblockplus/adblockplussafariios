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

import RxSwift

// For debugging KVO in the legacy implementation.
extension ABPManager {
    func activatedSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Bool.self,
                           ABPState.activated.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: { activated in
                NSLog("activated \(String(describing: activated))")
            })
    }

    func lastActivitySubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Date.self,
                           ABPState.lastActivity.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: { lastActivity in
                NSLog("last activity \(String(describing: lastActivity))")
            })
    }

    func performingActivityTestSubscription() -> Disposable {
        return adblockPlus.rx
            .observeWeakly(Bool.self,
                           ABPState.performingActivityTest.rawValue,
                           options: [.initial, .new])
            .subscribe(onNext: { performingActivityTest in
                NSLog("performingActivityTest \(String(describing: performingActivityTest))")
            })
    }
}
