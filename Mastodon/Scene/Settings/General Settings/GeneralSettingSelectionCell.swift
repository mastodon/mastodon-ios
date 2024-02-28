// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset
import MastodonUI

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
        tintColor = Asset.Colors.Brand.blurple.color
        accessoryType = .disclosureIndicator
        
        var content = defaultContentConfiguration()
        content.prefersSideBySideTextAndSecondaryText = true
        content.text = setting.title
        
        if let text = LanguagePicker.availableLanguages().first(where: { $0.localeId == UserDefaults.shared.defaultPostLanguage })?.exonym {
            content.secondaryAttributedText = NSAttributedString(
                string: text,
                attributes: [
                    .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
                    .foregroundColor: Asset.Colors.inactive.color
                ]
            )
        }

        contentConfiguration = content
    }

}
