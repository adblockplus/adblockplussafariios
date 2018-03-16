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

extension UIView {
    /// Constrain to another view with side margins and full vertical layout.
    /// - Parameter view: The view to set constraints against.
    /// - Returns: Array of constraints.
    func sideMarginFullVertical(to view: UIView) -> [NSLayoutConstraint] {
        return
            [equalAttributeConstraint(to: view,
                                      attribute: .top),
             equalAttributeConstraint(to: view,
                                      attribute: .bottom),
             equalAttributeConstraint(to: view,
                                      attribute: .leadingMargin),
             equalAttributeConstraint(to: view,
                                      attribute: .trailingMargin)]
    }

    /// Make a constraint with equal attributes.
    /// - Parameters:
    ///   - view: The view to set constraints against.
    ///   - attribute: A layout attribute.
    /// - Returns: A constraint.
    fileprivate func equalAttributeConstraint(to view: UIView,
                                              attribute: NSLayoutAttribute) -> NSLayoutConstraint {
        return
            NSLayoutConstraint(item: self,
                               attribute: attribute,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: attribute,
                               multiplier: 1,
                               constant: 0)
    }
}
