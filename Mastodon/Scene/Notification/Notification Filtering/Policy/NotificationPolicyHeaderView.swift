// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit

class NotificationPolicyHeaderView: UIView {
    let titleLabel: UILabel
    let closeButton: UIButton

    override init(frame: CGRect) {

        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: 20, weight: .bold))
        // TODO: Localization
        titleLabel.text = "Filter Notifications from..."

        closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setInsets(forContentPadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), imageTitlePadding: 0)
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
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 20),
            bottomAnchor.constraint(greaterThanOrEqualTo: closeButton.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
