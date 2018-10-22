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

/// Intended to represent all available keys for trigger resource-type.
/// See [Introduction to WebKit Content Blockers](https://webkit.org/blog/3476/content-blockers-first-look/).
enum TriggerResourceType: String,
                          Codable {
    case document
    case image
    case styleSheet = "style-sheet"
    case script
    case font
    case raw // any untyped load, like XMLHttpRequest
    case svgDocument = "svg-document"
    case media
    case popup
}

struct Trigger: Decodable,
                Encodable {
    var ifDomain: [String]?
    var loadType: [String]?
    var resourceType: [TriggerResourceType]?
    var unlessDomain: [String]?
    var urlFilter: String?
    var urlFilterIsCaseSensitive: Bool?

    // Keys here are intended to be comprehensive for WebKit content-blocking triggers.
    enum CodingKeys: String,
                     CodingKey {
        case ifDomain = "if-domain"
        case loadType = "load-type"
        case resourceType = "resource-type"
        case unlessDomain = "unless-domain"
        case urlFilter = "url-filter"
        case urlFilterIsCaseSensitive = "url-filter-is-case-sensitive"
    }
}

struct Action: Decodable,
               Encodable {
    // Keys here are intended to be comprehensive for WebKit content-blocking actions.
    var selector: String?
    var type: String?
}

/// A filter list WebKit content blocking rule.
/// Used for decoding individual rules.
public struct BlockingRule: Decodable,
                            Encodable {
    var action: Action?
    var trigger: Trigger?

    // Keys here are intended to be comprehensive for WebKit content-blocking rules.
    enum CodingKeys: String,
                     CodingKey {
        case action
        case trigger
    }
}

/// A Filter List is also known as a Block List within the context of content
/// blocking on iOS/macOS.
///
/// This struct is used for decoding all rules where the rules are unkeyed.
/// This is for verification and handling of v1 filter lists in JSON format.
public struct V1FilterList: Decodable {
    var container: UnkeyedDecodingContainer!

    public init(from decoder: Decoder) {
        guard let container = try? decoder.unkeyedContainer() else {
            return
        }
        self.container = container
    }
}

extension V1FilterList {
    /// - returns: Observable of filter list rules
    func rules() -> Observable<BlockingRule> {
        var mself = self // copy
        guard let container = mself.container,
              let count = container.count,
              count > 0
        else {
            return Observable.empty()
        }
        return Observable.create { observer in
            while !mself.container.isAtEnd {
                var rule = BlockingRule()
                if let contents =
                    try? mself
                        .container
                        .nestedContainer(keyedBy: BlockingRule.CodingKeys.self) {
                    if let decoded =
                        try? contents.decodeIfPresent(Trigger.self,
                                                      forKey: .trigger) {
                        rule.trigger = decoded
                    }
                    if let decoded =
                        try? contents.decodeIfPresent(Action.self,
                                                      forKey: .action) {
                        rule.action = decoded
                    } else {
                        observer.onError(ABPFilterListError.failedDecoding)
                    }
                    if rule.trigger != nil && rule.action != nil {
                        observer.onNext(rule)
                    }
                } else {
                    observer.onError(ABPFilterListError.badContainer)
                }
            }
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
