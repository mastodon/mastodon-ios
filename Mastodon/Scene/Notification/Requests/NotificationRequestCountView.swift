// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class NotificationRequestCountView: UIView {
    
    let countLabel: UILabel

    init() {
        countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.textColor = .white
        countLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        countLabel.textAlignment = .center

        super.init(frame: .zero)

        addSubview(countLabel)

        backgroundColor = Asset.Colors.Brand.blurple.color
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.white.cgColor
        applyCornerRadius(radius: 10)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            trailingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: 5),
            bottomAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 2),

            widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
