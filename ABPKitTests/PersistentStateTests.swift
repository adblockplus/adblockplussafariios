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

@testable import ABPKit

import RxCocoa
import RxSwift
import XCTest

/// Test a selection of representative types for data persistence and KVO on a
/// data store.
///
/// The tested types include the following:
/// * Bool
/// * Int
/// * Date
/// * [String]
// swiftlint:disable type_body_length
class PersistentStateTests: XCTestCase {
    let abpms = ABPMutableState()
    var defaults: UserDefaults!
    let random = { maxInt in return Int(arc4random_uniform(maxInt + 1)) }
    let scheduler = MainScheduler.asyncInstance
    let testInterval = { return max(Double(arc4random_uniform(3)) * 0.1, 0.01) }
    let testLength = 15.0
    var bag: DisposeBag!
    var currentArrayStringState: [String]?
    var currentBoolState: Bool?
    var currentDateState: Date?
    var currentIntState: Int?
    var currentKey: String?
    var obsCnt: Int!
    var pstr: Persistor!
    var setCnt = 0
    var observers: [Disposable?]!

    /// Generic observe action.
    /// The state == nil checks prevent crashing.
    func observeAction<U>() -> (U) -> Void {
        // swiftlint:disable force_cast
        let failMsg: (U, U) -> String = { currState, val in
            return ABPMutableStateError.invalidData.localizedDescription +
            " - current state \(String(describing: currState)) ≠ \(val)"
        }
        return { [weak self] val in
            if val as? Bool != nil {
                if self?.currentBoolState == nil { return }
                XCTAssert(val as? Bool == self?.currentBoolState,
                          failMsg(self?.currentBoolState as! U, val))
            } else if val as? Int != nil {
                if self?.currentIntState == nil { return }
                XCTAssert(val as? Int == self?.currentIntState,
                          failMsg(self?.currentIntState as! U, val))
            } else if val as? Date != nil {
                if self?.currentDateState == nil { return }
                XCTAssert(val as? Date == self?.currentDateState,
                          failMsg(self?.currentDateState as! U, val))
            } else if val as? [String] != nil {
                if self == nil || self?.currentArrayStringState == nil { return }
                XCTAssert((val as! [String]).elementsEqual(self!.currentArrayStringState!),
                          failMsg(self?.currentArrayStringState as! U, val))
            } else { XCTFail("❌ Bad state - val \(val), type \(type(of: U.self))") }
            NSLog("🔑\(String(describing: self?.currentKey)) = \(val)")
            self?.obsCnt? += 1
        }
        // swiftlint:enable force_cast
    }

    /// Tests will not terminate without the proper observers.
    override func setUp() {
        super.setUp()
        bag = DisposeBag()
        pstr = Persistor()
        let cfg = Config()
        guard let dflts = try? UserDefaults(suiteName: cfg.defaultsSuiteName()) else {
            XCTFail("Bad user defaults.")
            return
        }
        defaults = dflts
        observers = [Disposable]()
        observers?.append(
            pstr.observe(dataType: Bool.self,
                         key: .acceptableAdsEnabled,
                         nextAction: observeAction())
        )
        observers?.append(
            pstr.observe(dataType: Int.self,
                         key: .downloadedVersion,
                         nextAction: observeAction())
        )
        observers?.append(
            pstr.unsafeObserve(dataType: Date.self,
                               key: .lastActivity,
                               nextAction: observeAction())
        )
        observers?.append(
            pstr.unsafeObserve(dataType: [String].self,
                               key: .whitelistedWebsites,
                               nextAction: observeAction())
        )
    }

    override func tearDown() {
        observers.forEach {
            if $0 != nil {
                $0?.dispose()
            }
        }
        super.tearDown()
    }

    /// Types for testing against the standard library.
    enum DefaultsSetType: String {
        case stdlib
        case custom
    }

    func stateTester<U>(metatype: U.Type,
                        key: ABPMutableState.LegacyStateName,
                        setType: DefaultsSetType) -> Observable<(Int, ABPMutableState.LegacyStateName)> {
        var iterCnt = 0
        return Observable<Int>
            .interval(testInterval(),
                      scheduler: scheduler)
            .takeWhile { _ in
                if self.obsCnt > 3 { return false }
                return true
            }
            .flatMap { count -> Observable<(Int, ABPMutableState.LegacyStateName)> in
                guard let state = self.randomState(for: U.self) else {
                    XCTFail(ABPMutableStateError.invalidData.localizedDescription)
                    return Observable.error(ABPMutableStateError.invalidData)
                }
                self.updateCurrentState(val: state)
                self.currentKey = key.rawValue
                switch setType {
                case .stdlib:
                    self.defaults?.set(state,
                                       forKey: key.rawValue)
                case .custom:
                    self.setValue(val: state,
                                  key: key)
                }
                iterCnt += 1
                return Observable.create { observer in
                    NSLog("local iteration for \(key): \(iterCnt), set state with \(state) ⬅️")
                    observer.onNext((count, key))
                    observer.onCompleted() // essential
                    return Disposables.create()
                }
            }
    }

    func resetter() -> Observable<(Int, ABPMutableState.LegacyStateName)> {
        return Observable<Int>
            .interval(testInterval(),
                      scheduler: scheduler)
            .takeWhile { cnt in
                if cnt > 1 { return false }
                return true
            }
            .flatMap { _ -> Observable<(Int, ABPMutableState.LegacyStateName)> in
                self.obsCnt = 0
                return Observable.just((0, .empty))
            }
    }

    /// Resetter initializes the state testing.
    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    // swiftlint:disable opening_brace
    func testLegacyStateTypes() {
        let expect = expectation(description: #function)
        Observable.concat([
            resetter(),
            stateTester(metatype: Bool.self, key: .acceptableAdsEnabled, setType: .stdlib),
            resetter(),
            stateTester(metatype: Bool.self, key: .acceptableAdsEnabled, setType: .custom),
            resetter(),
            stateTester(metatype: Int.self, key: .downloadedVersion, setType: .stdlib),
            resetter(),
            stateTester(metatype: Int.self, key: .downloadedVersion, setType: .custom),
            resetter(),
            stateTester(metatype: Date.self, key: .lastActivity, setType: .stdlib),
            resetter(),
            stateTester(metatype: Date.self, key: .lastActivity, setType: .custom),
            resetter(),
            stateTester(metatype: [String].self, key: .whitelistedWebsites, setType: .stdlib),
            resetter(),
            stateTester(metatype: [String].self, key: .whitelistedWebsites, setType: .custom)
        ])
            .subscribeOn(scheduler)
            .subscribe(onNext: { iter, key in
                guard let obsCnt = self.obsCnt else { return }
                NSLog("⏱iteration \(iter), obsCnt \(obsCnt), key \(key) ✔️")
                switch key {
                case .acceptableAdsEnabled:
                    let state1 = self.defaults?.bool(forKey: key.rawValue)
                    let state2 = try? self.pstr.load(type: Bool.self, key: key)
                    guard state1 != nil, state2 != nil, let curr = self.currentBoolState else { XCTFail("Found nil."); return }
                    XCTAssert(state1 == state2, "Error: state1 \(state1!) ≠ state2 \(state2!)")
                    XCTAssert(state2 == curr, "Error: state \(state2!) ≠ \(curr)")
                case .downloadedVersion:
                    let state1 = self.defaults?.integer(forKey: key.rawValue)
                    let state2 = try? self.pstr.load(type: Int.self, key: key)
                    guard state1 != nil, state2 != nil, let curr = self.currentIntState else { XCTFail("Found nil."); return }
                    XCTAssert(state1 == state2, "Error: state1 \(state1!) ≠ state2 \(state2!)")
                    XCTAssert(state2 == curr, "Error: state \(state2!) ≠ \(curr)")
                case .lastActivity:
                    let state1 = self.defaults?.value(forKey: key.rawValue) as? Date
                    let state2 = try? self.pstr.load(type: Date.self, key: key)
                    guard state1 != nil, state2 != nil, let curr = self.currentDateState else { XCTFail("Found nil."); return }
                    XCTAssert(state1 == state2, "Error: state1 \(state1!) ≠ state2 \(state2!)")
                    XCTAssert(state2 == curr, "Error: state \(state2!) ≠ \(curr)")
                case .whitelistedWebsites:
                    let state1 = self.defaults?.array(forKey: key.rawValue) as? [String]
                    let state2 = try? self.pstr.load(type: [String].self, key: key)
                    guard state1 != nil, state2 != nil, let curr = self.currentArrayStringState else { XCTFail("Found nil."); return }
                    XCTAssert(state1 == state2, "Error: state1 \(state1!) ≠ state2 \(state2!)")
                    XCTAssert(state2!.elementsEqual(state1!), "Error: state \(state2!) ≠ \(curr)")
                    XCTAssert(state2!.elementsEqual(curr), "Error: state \(state2!) ≠ \(curr)")
                case .empty:
                    {}() //no-op
                default:
                    XCTFail("Bad state.")
                }
            }, onCompleted: {
                expect.fulfill()
            }, onDisposed: {
                 // The following nil settings are critical for the dispose test.
                self.currentBoolState = nil
                self.currentIntState = nil
                self.currentDateState = nil
                self.currentArrayStringState = nil
            }).disposed(by: bag)
        wait(for: [expect],
             timeout: testLength)
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length
    // swiftlint:enable opening_brace

    // ------------------------------------------------------------
    // MARK: - Private -
    // ------------------------------------------------------------

    func setValue<U>(val: U,
                     key: ABPMutableState.LegacyStateName) {
        self.updateCurrentState(val: val)
        // swiftlint:disable unused_optional_binding
        guard let _ =
            try? self.pstr.save(type: U.self,
                                value: val,
                                key: key)
        else {
            XCTFail("Save failed.")
            return
        }
        self.setCnt += 1
        // swiftlint:enable unused_optional_binding
    }

    func updateCurrentState<U>(val: U) {
        if type(of: val) == Bool.self {
            currentBoolState = val as? Bool
        } else if type(of: val) == Int.self {
            currentIntState = val as? Int
        } else if type(of: val) == Date.self {
            currentDateState = val as? Date
        } else if type(of: val) == [String].self {
            currentArrayStringState = val as? [String]
        }
    }

    func randomState<U>(for metatype: U.Type) -> U? {
        if metatype == Bool.self {
            if random(1) == 1 { return true as? U }
            return false as? U
        } else if metatype == Int.self {
            if random(1) == 1 { return 1 as? U }
            return 0 as? U
        } else if metatype == Date.self {
            return Date() +
                   TimeInterval(random(10)) *
                   Constants.defaultFilterListExpiration as? U
        } else if metatype == [String].self {
            let chars = "abcdefghijklmnopqrstuvwxyz"
            let countMax = random(11)
            var arr = [String]()
            for _ in 0...countMax {
                let idx = chars.index(chars.startIndex,
                                      offsetBy: random(UInt32(chars.count - 1)))
                arr.append(String(chars[idx]))
            }
            return arr as? U
        }
        return nil
    }
}
// swiftlint:enable type_body_length
