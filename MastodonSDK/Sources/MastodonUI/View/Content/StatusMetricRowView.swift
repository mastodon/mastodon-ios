// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

public final class StatusMetricRowView: UIButton {
    let icon: UIImageView
    let textLabel: UILabel
    let detailLabel: UILabel
    let chevron: UIImageView

    public init(iconImage: UIImage? = nil, text: String? = nil, detailText: String? = nil) {

        icon = UIImageView(image: iconImage?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = Asset.Colors.Label.secondary.color
        icon.translatesAutoresizingMaskIntoConstraints = false

        textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        textLabel.textColor = Asset.Colors.Label.primary.color
        textLabel.numberOfLines = 0
        textLabel.text = text

        detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.text = detailText
        detailLabel.textColor = Asset.Colors.Label.secondary.color
        detailLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))

        chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = Asset.Colors.Label.tertiary.color

        super.init(frame: .zero)

        addSubview(icon)
        addSubview(textLabel)
        addSubview(detailLabel)
        addSubview(chevron)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            icon.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            icon.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            icon.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            bottomAnchor.constraint(greaterThanOrEqualTo: icon.bottomAnchor, constant: 10),

            textLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 11),
            detailLabel.leadingAnchor.constraint(greaterThanOrEqualTo: textLabel.trailingAnchor, constant: 8),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: textLabel.bottomAnchor, constant: 11),

            detailLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 11),
            chevron.leadingAnchor.constraint(greaterThanOrEqualTo: detailLabel.trailingAnchor, constant: 12),
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: detailLabel.bottomAnchor, constant: 11),

            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            trailingAnchor.constraint(equalTo: chevron.trailingAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
