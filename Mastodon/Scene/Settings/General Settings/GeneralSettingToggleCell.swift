// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

protocol GeneralSettingToggleCellDelegate: AnyObject {
    func toggle(_ cell: GeneralSettingToggleCell, setting: GeneralSetting, isOn: Bool)
}

class GeneralSettingToggleCell: UITableViewCell {
    static let reuseIdentifier = "GeneralSettingToggleCell"

    let label: UILabel
    let toggle: UISwitch
    weak var delegate: GeneralSettingToggleCellDelegate?

    var setting: GeneralSetting?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.numberOfLines = 0

        toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = Asset.Colors.Brand.blurple.color

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        toggle.addTarget(self, action: #selector(GeneralSettingToggleCell.toggleValueChanged(_:)), for: .valueChanged)

        contentView.addSubview(label)
        contentView.addSubview(toggle)
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 11),

            toggle.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 16),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: toggle.trailingAnchor, constant: 16)

        ]
        NSLayoutConstraint.activate(constraints)
    }

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
