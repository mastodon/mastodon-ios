// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class GeneralSettingSelectionCell: UITableViewCell {
    static let reuseIdentifier = "GeneralSettingSelectionCell"

    func configure(with setting: GeneralSetting, viewModel: GeneralSettingsViewModel) {
        switch setting {
        case let .appearance(appearanceSetting):
            configureAppearanceSetting(appearanceSetting: appearanceSetting, viewModel: viewModel)
        case .askBefore:
            assertionFailure("Not required here")
        case .design:
            // only for appearance and open links
            assertionFailure("Wrong Setting!")
        case let .language(setting):
            configureLanguageSetting(setting, viewModel: viewModel)
        case let .openLinksIn(openLinkSetting):
            configureOpenLinkSetting(openLinkSetting: openLinkSetting, viewModel: viewModel)
        }
    }
    
    private func configureAppearanceSetting(appearanceSetting: GeneralSetting.Appearance, viewModel: GeneralSettingsViewModel) {
        var content = defaultContentConfiguration()
        content.text = appearanceSetting.title
        tintColor = Asset.Colors.Brand.blurple.color

        if viewModel.selectedAppearence == appearanceSetting {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }

        contentConfiguration = content
    }
    
    private func configureOpenLinkSetting(openLinkSetting: GeneralSetting.OpenLinksIn, viewModel: GeneralSettingsViewModel) {
        var content = defaultContentConfiguration()
        content.text = openLinkSetting.title
        tintColor = Asset.Colors.Brand.blurple.color

        if viewModel.selectedOpenLinks == openLinkSetting {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }

        contentConfiguration = content
    }
    
    private func configureLanguageSetting(_ setting: GeneralSetting.Language, viewModel: GeneralSettingsViewModel) {
        var content = defaultContentConfiguration()
        content.text = setting.title
        tintColor = Asset.Colors.Brand.blurple.color

        content.secondaryText = viewModel.defaultPostLanguage
        content.prefersSideBySideTextAndSecondaryText = true

        contentConfiguration = content
    }

}
