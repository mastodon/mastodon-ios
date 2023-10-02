// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

class GeneralSettingsDiffableTableViewDataSource: UITableViewDiffableDataSource<GeneralSettingsSection, GeneralSetting> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let settingsSection = sectionIdentifier(for: section) else { return nil }

        return settingsSection.type.sectionTitle.uppercased()
    }
}
