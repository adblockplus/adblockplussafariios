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

// For localization of strings.
extension ActionViewController {
    /// Manually localize attributed strings as they are not exported from the storyboard.
    func localizeAttributedStrings() {
        let contentWillNotBeBlocked
            = NSLocalizedString("content-will-not-be-blocked.text",
                                value: "Content will not be blocked on this website. It may take a few seconds for this setting to take effect.",
                                comment: "Label describing that content will not be blocked for the whitelisted website.")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineHeightMultiple = 1.5
        let attribs = [
            NSAttributedStringKey
                .foregroundColor: UIColor(hue: 0.611,
                                          saturation: 0.031,
                                          brightness: 0.380,
                                          alpha: 1),
                .font: UIFont.systemFont(ofSize: 11),
                .paragraphStyle: paragraphStyle]
        let attribString = NSAttributedString(string: contentWillNotBeBlocked,
                                              attributes: attribs)
        contentWillNotBeBlockedLabel.attributedText = attribString
    }
}
