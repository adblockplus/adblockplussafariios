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

/// Handle whitelisting of websites.
extension ABPManager {
    /// Return websites that have been added to the whitelist from the URL Session tasks.
    func whitelistedWebsites(forSessionID sessionID: String) -> Observable<[WhiteListedWebsite]> {
        if !adblockPlus.isBackgroundNotificationSessionConfigurationIdentifier(sessionID) {
            return Observable.just([])
        }
        return tasks(forSessionID: sessionID)
    }

    /// Process the websites found within the tasks using a background thread with high priority.
    private func tasks(forSessionID sessionID: String) -> Observable<[WhiteListedWebsite]> {
        return Observable.create { observer in
            let config = URLSessionConfiguration.background(withIdentifier: sessionID)
            let session = URLSession(configuration: config,
                                     delegate: nil,
                                     delegateQueue: nil)
            session.getAllTasks { (tasks: [URLSessionTask]) in
                let websites = tasks.map {
                    self.website(fromURL: $0.originalRequest?.url)
                }.flatMap { website in
                    // Nil members in the websites array have been removed by flatMap.
                    ABPManager.sharedInstance().adblockPlus.whitelistWebsite(website!)
                    return website
                }
                observer.onNext(websites)
                observer.onCompleted()
            }
            return Disposables.create()
        }.observeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
    }

    /// Extract the name of the whitelisted website from a URL.
    private func website(fromURL url: URL?) -> String? {
        let components = url?.query?.components(separatedBy: "&") ?? []
        let prefix = "website="
        let websites = components.filter { $0.hasPrefix(prefix) }
        if websites.count == 1 {
            return websites
                .map { $0.replacingOccurrences(of: prefix, with: "") }
                .reduce("") { $0 + $1 }
        }
        return nil
    }
}
