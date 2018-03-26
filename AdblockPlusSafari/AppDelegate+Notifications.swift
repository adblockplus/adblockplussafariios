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
import RxSwiftExt

extension AppDelegate {
    typealias DeviceToken = String

    /// Register for remote notifications used for background updates.
    func registerForNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Registration for remote notifications has completed successfully.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let maxRetryCount: UInt = 10
        let retryDelay: Double = (GlobalConstants.tokenSaveTimeout - 1) / Double(maxRetryCount)
        httpClient = HTTPClient()
        guard let client = httpClient else { return }
        deviceTokenSave(token: deviceToken.reduce("", { $0 + String(format: "%02X", $1) }),
                        client: client)
            .retry(.delayed(maxCount: maxRetryCount,
                            time: retryDelay))
            .subscribe(onCompleted: {
                self.httpClient = nil
            }).disposed(by: bag)
    }

    /// Update an expired filter list.
    /// - Parameter completion: Complete with the result of the background fetch.
    /// - Returns: A disposable to be called.
    func updateSubscription(completion: @escaping (UIBackgroundFetchResult) -> Void) -> Disposable {
        guard let updater = ABPManager.sharedInstance().filterListsUpdater else {
            return Disposables.create()
        }
        return updater.expiredFilterListUpdate()
            .subscribe(onNext: { updated in
                if updated {
                    completion(.newData)
                } else {
                    completion(.noData)
                }
            }, onError: { _ in
                completion(.failed)
            })
    }

    /// Determine if the command is to update the filter list.
    /// - Parameter commandString: A string with a potential remote command.
    /// - Returns: True if the command was to update, false otherwise.
    func shouldUpdateFilterList(for commandString: String?) -> Bool {
        if let command = commandString,
           ABPRemoteCommand(rawValue: command) == ABPRemoteCommand.updateFilterList {
            return true
        }
        return false
    }

    /// Handle receiving notifications in background and foreground states. The completion handler
    /// is called after updates are completed or after it is known that no updates are needed or
    /// after an error.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let commandKey = "command"
        let state = application.applicationState
        if state == .background ||
           state == .inactive &&
           !startingApp.value {
            // App is in the background.
            if shouldUpdateFilterList(for: userInfo[commandKey] as? String) {
                updateSubscription(completion: completionHandler)
                    .disposed(by: bag)
            } else {
                completionHandler(.failed)
            }
        } else if state == .inactive &&
                  startingApp.value {
            // App is starting.
            completionHandler(.noData)
        } else {
            // App is active.
            if shouldUpdateFilterList(for: userInfo[commandKey] as? String) {
                updateSubscription(completion: completionHandler)
                    .disposed(by: bag)
            }
        }
    }

    /// Send an app-specific device token for saving. Importantly, the http client is not constructed
    /// within this function but is used for testing it.
    /// - Parameters:
    ///   - token: App-specific device token.
    ///   - client: Provides URL session. Also used for testing this function.
    /// - Returns: Observable of device token saved.
    func deviceTokenSave(token: DeviceToken,
                         client: HTTPClient) -> Observable<DeviceToken> {
        return Observable.create { observer in
            guard let endpoint = ABPAPIData.endpointReceiveDeviceData(),
                  let url = URL(string: endpoint)
            else {
                observer.onError(ABPDeviceTokenSaveError.invalidEndpoint)
                return Disposables.create()
            }
            let request = self.makeRequest(with: token, url: url)
            let task = client.session.dataTask(with: request) { _, _, error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                observer.onNext(token)
                observer.onCompleted()
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }.timeout(GlobalConstants.tokenSaveTimeout,
                  scheduler: MainScheduler.asyncInstance)
    }

    private func makeRequest(with token: DeviceToken,
                             url: URL) -> URLRequest {
        let deviceTokenKey = "deviceToken"
        let appTypeKey = "appType"
        let postMethod = "POST"
        let apiKeyHeader = "X-API-KEY"
        let json: [String: Any] =
            [deviceTokenKey: token,
             appTypeKey: AppType().abpTypeID]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url)
        request.httpMethod = postMethod
        request.setValue(ABPAPIData.keyAPIReceiveDeviceData(),
                         forHTTPHeaderField: apiKeyHeader)
        request.httpBody = jsonData
        return request
    }
}
