// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class ToggleTableViewCell: UITableViewCell {
    class var reuseIdentifier: String {
        return "ToggleTableViewCell"
    }

    let label: UILabel
    let subtitleLabel: UILabel
    private let labelStackView: UIStackView
    let toggle: UISwitch

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.numberOfLines = 0

        subtitleLabel = UILabel()
        subtitleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        subtitleLabel.numberOfLines = 0

        labelStackView = UIStackView(arrangedSubviews: [label, subtitleLabel])
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical

        toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = Asset.Colors.Brand.blurple.color
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(labelStackView)
        contentView.addSubview(toggle)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupConstraints() {
        let constraints = [
            labelStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            labelStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: labelStackView.bottomAnchor, constant: 11),

            toggle.leadingAnchor.constraint(greaterThanOrEqualTo: labelStackView.trailingAnchor, constant: 16),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: toggle.trailingAnchor, constant: 16)
            
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
