// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class MastodonLoginServerTableViewCell: UITableViewCell {
    static let reuseIdentifier = "MastodonLoginServerTableViewCell"
    
    let separator: UIView
    let titleLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        separator = UIView.separatorLine
        separator.translatesAutoresizingMaskIntoConstraints = false

        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = Asset.Colors.Brand.blurple.color

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = Asset.Scene.Onboarding.textFieldBackground.color

        contentView.addSubview(titleLabel)
        contentView.addSubview(separator)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        titleLabel.text = nil
    }

    private func setupConstraints() {
        let separatorHeight = UIView.separatorLineHeight(of: contentView)
        let constraints = [
            separator.heightAnchor.constraint(equalToConstant: separatorHeight),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            contentView.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: separator.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            separator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 13),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    public func configure(domain: String, separatorHidden: Bool = false) {
        titleLabel.text = domain
        separator.isHidden = separatorHidden
    }
}
