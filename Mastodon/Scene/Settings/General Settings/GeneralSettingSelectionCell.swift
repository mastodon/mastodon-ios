// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

class GeneralSettingSelectionCell: UITableViewCell {
    static let reuseIdentifier = "GeneralSettingSelectionCell"

    func configure(with setting: GeneralSetting, viewModel: GeneralSettingsViewModel) {
        switch setting {
        case .appearance(let appearanceSetting):
            configureAppearanceSetting(appearanceSetting: appearanceSetting, viewModel: viewModel)
        case .design(_):
            // only for appearance and open links
            assertionFailure("Wrong Setting!")
        case .openLinksIn(let openLinkSetting):
            configureOpenLinkSetting(openLinkSetting: openLinkSetting, viewModel: viewModel)
        }
    }
    
    private func configureAppearanceSetting(appearanceSetting: GeneralSetting.Appearance, viewModel: GeneralSettingsViewModel) {
        textLabel?.text = appearanceSetting.title
        if viewModel.selectedAppearence == appearanceSetting {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }
    
    private func configureOpenLinkSetting(openLinkSetting: GeneralSetting.OpenLinksIn, viewModel: GeneralSettingsViewModel) {
        textLabel?.text = openLinkSetting.title
        if viewModel.selectedOpenLinks == openLinkSetting {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }

}
