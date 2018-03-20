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

/// ViewModel for Imprint.
struct ImprintVM {
    var contactFrom: String {
        return NSLocalizedString("Contact-From-ABP-For-iOS",
                                 value: "Contact from ABP for iOS",
                                 comment: "Used in mail subject to indicate source of contact.")
    }
    var imprint: URLRequest? {
        guard let path = Bundle.main.url(forResource: "imprint",
                                         withExtension: "html")
        else {
            return nil
        }
        return URLRequest(url: path)
    }
    let eyeoInfoEmail = "info@eyeo.com"
    var mailSubject = ""
    let mailBody = ""

    init() {
        mailSubject = contactFrom
    }
}
