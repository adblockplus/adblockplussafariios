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

import RxCocoa
import RxSwift

/// Show About.
class AboutTVC: UITableViewController {
    var bag: DisposeBag!
    var viewModel: AboutVM!
    @IBOutlet weak var versionLabel: UILabel!

    // ------------------------------------------------------------
    // MARK: - UIViewController -
    // ------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        bag = DisposeBag()
        viewModel = AboutVM()
        setupTableView()
    }

    // ------------------------------------------------------------
    // MARK: - UITableViewDelegate -
    // ------------------------------------------------------------

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        if viewModel.sectionTitles.count - 1 >= section {
            return viewModel.sectionTitles[section]
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        // Turn off the highlight after selection.
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }

    // ------------------------------------------------------------
    // MARK: - Private -
    // ------------------------------------------------------------

    private func setupTableView() {
        tableView.tableFooterView = UIView()
        versionLabel.text = viewModel.version
        handleSelections()
    }

    /// Handle link selections.
    private func handleSelections() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [unowned self] event in
                self.view.isUserInteractionEnabled = false
                let (section, index) = (event[0], event[1])
                if index <= self.viewModel.gdprIndexLinkMax &&
                   section == self.viewModel.gdprSection,
                   let url = URL(string: self.viewModel.links[index]) {
                    self.openURL(url)
                }
                self.view.isUserInteractionEnabled = true
            }).disposed(by: bag)
    }
}
