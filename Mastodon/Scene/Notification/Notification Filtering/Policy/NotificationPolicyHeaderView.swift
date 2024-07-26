// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

class NotificationPolicyHeaderView: UIView {
    let titleLabel: UILabel
    let closeButton: UIButton

    override init(frame: CGRect) {

        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: 20, weight: .bold))
        titleLabel.text = L10n.Scene.Notification.Policy.title


        let buttonImageConfiguration = UIImage
            .SymbolConfiguration(pointSize: 30)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .quaternarySystemFill]))
        let buttonImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: buttonImageConfiguration)
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.image = buttonImage
        buttonConfiguration.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 0)

        closeButton = UIButton(configuration: buttonConfiguration)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.contentMode = .center

        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(closeButton)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 20),
            bottomAnchor.constraint(greaterThanOrEqualTo: closeButton.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
