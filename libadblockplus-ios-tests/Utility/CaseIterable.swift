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

/// For iterating enums until Swift 4.2.
#if swift(>=4.2)
#else
protocol CaseIterable: Hashable {
    static func cases() -> AnySequence<Self>

    static var allCases: [Self] { get }
}

extension CaseIterable {
    static func cases() -> AnySequence<Self> {
        return AnySequence { () -> AnyIterator<Self> in
            var idx = 0 // memory index
            return AnyIterator {
                let val: Self =
                    withUnsafePointer(to: &idx) { arg in
                        arg.withMemoryRebound(to: self,
                                              capacity: 1) { ptr in
                            ptr.pointee // get value
                        }
                    }
                if val.hashValue != idx {
                    return nil // terminate sequence
                }
                idx += 1
                return val
            }
        }
    }

    static var allCases: [Self] {
        return Array(self.cases())
    }
}
#endif
