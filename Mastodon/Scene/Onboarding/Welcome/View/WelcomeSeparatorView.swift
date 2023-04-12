// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

class WelcomeSeparatorView: UIView {
    let leftLine: UIView
    let rightLine: UIView
    let label: UILabel

    override init(frame: CGRect) {
        leftLine = UIView()
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        leftLine.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        rightLine = UIView()
        rightLine.translatesAutoresizingMaskIntoConstraints = false
        rightLine.backgroundColor = UIColor.white.withAlphaComponent(0.6)

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.text = L10n.Scene.Welcome.Separator.or.uppercased()
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
        label.textColor = UIColor.white.withAlphaComponent(0.6)

        super.init(frame: frame)

        addSubview(leftLine)
        addSubview(label)
        addSubview(rightLine)

        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        let constraints = [

            label.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: label.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.leadingAnchor.constraint(equalTo: leftLine.trailingAnchor, constant: 8),
            leftLine.centerYAnchor.constraint(equalTo: centerYAnchor),

            rightLine.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: rightLine.trailingAnchor),
            rightLine.centerYAnchor.constraint(equalTo: centerYAnchor),

            leftLine.heightAnchor.constraint(equalToConstant: 1),
            rightLine.heightAnchor.constraint(equalTo: leftLine.heightAnchor),

        ]
        NSLayoutConstraint.activate(constraints)
    }
}
