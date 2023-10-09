// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

class AboutInstanceTableViewDataSource: UITableViewDiffableDataSource<AboutInstanceSection, AboutInstanceItem> {

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<AboutInstanceSection, AboutInstanceItem>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = AboutInstanceSection(rawValue: section) else { return nil }

        return section.title.uppercased()
    }
}
