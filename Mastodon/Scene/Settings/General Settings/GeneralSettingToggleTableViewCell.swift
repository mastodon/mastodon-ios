// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

protocol GeneralSettingToggleTableViewCellDelegate: AnyObject {
    func toggle(_ cell: GeneralSettingToggleTableViewCell, setting: GeneralSetting, isOn: Bool)
}

class GeneralSettingToggleTableViewCell: ToggleTableViewCell {
    override class var reuseIdentifier: String {
        return "GeneralSettingToggleCell"
    }

    weak var delegate: GeneralSettingToggleTableViewCellDelegate?
    var setting: GeneralSetting?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        subtitleLabel.isHidden = true
        toggle.addTarget(self, action: #selector(GeneralSettingToggleTableViewCell.toggleValueChanged(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with setting: GeneralSetting, viewModel: GeneralSettingsViewModel) {

        self.setting = setting

        switch setting {
        case .appearance, .openLinksIn, .language:
            assertionFailure("Not required here")
        case let .askBefore(askBefore):
            label.text = askBefore.title
            
            switch askBefore {
            case .postingWithoutAltText:
                toggle.isOn = UserDefaults.shared.askBeforePostingWithoutAltText
            case .unfollowingSomeone:
                toggle.isOn = UserDefaults.shared.askBeforeUnfollowingSomeone
            case .boostingAPost:
                toggle.isOn = UserDefaults.shared.askBeforeBoostingAPost
            case .deletingAPost:
                toggle.isOn = UserDefaults.shared.askBeforeDeletingAPost
            }
        case .design(let designSetting):
            label.text = designSetting.title

            switch designSetting {
            case .showAnimations:
                toggle.isOn = viewModel.playAnimations
            }
        }
    }

    @objc
    func toggleValueChanged(_ sender: UISwitch) {
        guard let setting else { return }

        delegate?.toggle(self, setting: setting, isOn: sender.isOn)
    }
}
