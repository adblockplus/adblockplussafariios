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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder,
                   UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if let uwController = window?.rootViewController as? RootController {
            uwController.adblockPlus = ABPManager.sharedInstance().adblockPlus
        }
        application.setMinimumBackgroundFetchInterval(GlobalConstants.backgroundFetchInterval)
        ikiLoggerEnabled = true
        ikiLoggerUseColor = true
        return true
    }

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        Appearance.apply()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        ABPManager.sharedInstance().handleDidEnterBackground()
    }

    /// Set background task state to invalid.
    func applicationWillEnterForeground(_ application: UIApplication) {
        ABPManager.sharedInstance().backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }

    // ------------------------------------------------------------
    // MARK: - Background mode -
    // ------------------------------------------------------------

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ABPManager.sharedInstance().handlePerformFetch(withCompletionHandler: completionHandler)
    }

    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        ABPManager.sharedInstance().handleEventsForBackgroundURLSession(identifier: identifier,
                                                                        completion: completionHandler)
    }
}
