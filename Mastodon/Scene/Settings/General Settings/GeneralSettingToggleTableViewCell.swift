// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

protocol GeneralSettingToggleCellDelegate: AnyObject {
    func toggle(_ cell: GeneralSettingToggleTableViewCell, setting: GeneralSetting, isOn: Bool)
}

class GeneralSettingToggleTableViewCell: ToggleTableViewCell {
    override class var reuseIdentifier: String {
        return "GeneralSettingToggleCell"
    }

    weak var delegate: GeneralSettingToggleCellDelegate?
    var setting: GeneralSetting?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        toggle.addTarget(self, action: #selector(GeneralSettingToggleTableViewCell.toggleValueChanged(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with setting: GeneralSetting, viewModel: GeneralSettingsViewModel) {

        self.setting = setting

        switch setting {
        case .appearance(_), .openLinksIn(_):
            assertionFailure("Only for Design")
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
