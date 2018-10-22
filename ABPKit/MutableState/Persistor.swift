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

import RxCocoa
import RxSwift

/// Persistent storage operations for UserDefaults backed storage:
/// * observe
/// * save
/// * load
/// * clear
class Persistor {
    typealias Action = (_ value: Any) -> Void
    /// Scheduler for all operations, main thread subscription is necessary for correct results.
    let scheduler = MainScheduler.asyncInstance
    let defaults: UserDefaults!

    init?() {
        let cfg = Config()
        guard let dflts = try? UserDefaults(suiteName: cfg.defaultsSuiteName()) else {
            return nil
        }
        defaults = dflts
    }

    /// Observe changes in the value for a key in defaults.
    /// Perform an action on every next event.
    func observe<T>(dataType: T.Type,
                    key: ABPMutableState.LegacyStateName,
                    nextAction: @escaping Action) -> Disposable? where T: (KVORepresentable) {
        return defaults?.rx
            .observe(dataType,
                     key.rawValue,
                     options: [.initial,
                               .new],
                     retainSelf: false)
            .subscribeOn(scheduler)
            .subscribe(onNext: { next in
                guard let val = next else {
                    return
                }
                nextAction(val)
            })
    }

    /// Return an observer for non KVORepresentable types.
    func unsafeObserve<T>(dataType: T.Type,
                          key: ABPMutableState.LegacyStateName,
                          nextAction: @escaping Action) -> Disposable? {
        return defaults?.rx
            .observe(dataType,
                     key.rawValue,
                     options: [.initial,
                               .new],
                     retainSelf: false)
            .subscribeOn(scheduler)
            .subscribe(onNext: { next in
                guard let val = next else {
                    return
                }
                nextAction(val)
            })
    }

    /// Save a value to a key path in defaults.
    func save<T>(type: T.Type,
                 value: T,
                 key: ABPMutableState.LegacyStateName) throws {
        guard let defaults = self.defaults else {
            throw ABPMutableStateError.missingDefaults
        }
        defaults
            .setValue(value,
                      forKey: key.rawValue)
    }

    /// This function should not not return nil.
    func load<T>(type: T.Type,
                 key: ABPMutableState.LegacyStateName) throws -> T {
        guard let defaults = self.defaults else {
            throw ABPMutableStateError.missingDefaults
        }
        guard let res = defaults.value(forKeyPath: key.rawValue) as? T else {
            throw ABPMutableStateError.invalidType
        }
        return res
    }

    func clear(key: ABPMutableState.LegacyStateName) throws {
        guard let defaults = self.defaults else {
            throw ABPMutableStateError.missingDefaults
        }
        defaults
            .setValue(nil,
                      forKey: key.rawValue)
    }
}
