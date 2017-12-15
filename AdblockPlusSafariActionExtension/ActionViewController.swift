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

import MobileCoreServices
import SafariServices
import UIKit

class ActionViewController: UIViewController {

    var adblockPlus: AdblockPlusShared?
    var website: String?
    var components: URLComponents?

    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var addressField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        adblockPlus = AdblockPlusShared()

        for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
            for itemProvider in item.attachments as? [NSItemProvider] ?? [] {
                let typeIdentifier = kUTTypePropertyList as String
                if itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                    itemProvider.loadItem(forTypeIdentifier: typeIdentifier,
                                          options: nil,
                                          completionHandler: { [weak self] item, error in
                                              guard let uwItem = item as? [String: NSDictionary], error == nil else { return }
                                              DispatchQueue.main.async {
                                                  if let results = uwItem[NSExtensionJavaScriptPreprocessingResultsKey],
                                                      let baseURI = results["baseURI"] as? String {
                                                      let hostname = baseURI as NSString
                                                      let whitelistedHostname = hostname.whitelistedHostname()
                                                      self?.website = baseURI
                                                      self?.addressField.text = whitelistedHostname
                                                      self?.descriptionField.text = results["title"] as? String
                                                  }
                                              }
                                          })
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.transition(with: view,
                          duration: 0.4,
                          options: [.transitionCrossDissolve, .showHideTransitionViews],
                          animations: { self.view.isHidden = false },
                          completion: nil)
    }

    @IBAction func onCancelButtonTouched(_ sender: UIButton) {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @IBAction func onDoneButtonTouched(_ sender: UIButton) {
        guard let uwWebsite = website as NSString? else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let whitelistedWebsite = uwWebsite.whitelistedHostname()
        if let uwWhitelistedWebsite = whitelistedWebsite {
            let time = Date.timeIntervalSinceReferenceDate
            components = URLComponents()
            components?.scheme = "http"
            components?.host = "localhost"
            components?.path = String(format: "/invalidimage-%d.png", Int(time))
            components?.query = String(format: "website=%@", uwWhitelistedWebsite)

            extensionContext?.completeRequest(returningItems: nil, completionHandler: { _ in
                self.completeAndExit()
            })
        }
    }

    func completeAndExit() {
        // Session must be created with new identifier, see Apple documentation:
        // https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html
        // Section - Performing Uploads and Downloads
        // Because only one process can use a background session at a time,
        // you need to create a different background session for the containing app and each of its app extensions.
        // (Each background session should have a unique identifier.)
        if let uwABP = adblockPlus {
            let identifier = uwABP.generateBackgroundNotificationSessionConfigurationIdentifier()
            let session = uwABP.backgroundNotificationSession(withIdentifier: identifier, delegate: nil)

            // Fake URL, request will definitely fail, hopefully the invalid url will be denied by iOS itself.
            if let uwURL = components?.url {

                // Start download request with fake URL
                let task = session.downloadTask(with: uwURL)
                task.resume()
                session.finishTasksAndInvalidate()

                // Let the host application to handle the result of download task
                exit(0)
            }
        }
    }
}
