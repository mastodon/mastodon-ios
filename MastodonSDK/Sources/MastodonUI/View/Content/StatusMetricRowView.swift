// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

public final class StatusMetricRowView: UIButton {
    let icon: UIImageView
    let textLabel: UILabel
    let detailLabel: UILabel
    let chevron: UIImageView

    private let contentStack: UIStackView

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

        contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.distribution = .fill
        contentStack.spacing = 8
        contentStack.addArrangedSubview(textLabel)
        contentStack.addArrangedSubview(detailLabel)

        super.init(frame: .zero)

        self.traitCollectionDidChange(nil)

        addSubview(icon)
        addSubview(contentStack)
        addSubview(chevron)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            contentStack.axis = .vertical
            contentStack.alignment = .fill
            detailLabel.textAlignment = .natural
        } else {
            contentStack.axis = .horizontal
            contentStack.alignment = .leading
            switch traitCollection.layoutDirection {
            case .leftToRight, .unspecified: detailLabel.textAlignment = .right
            case .rightToLeft: detailLabel.textAlignment = .left
            @unknown default:
                break
            }
        }
    }

    var margin: CGFloat = 0 {
        didSet {
            layoutMargins = UIEdgeInsets(horizontal: margin, vertical: 0)
        }
    }

    private func setupConstraints() {
        icon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        chevron.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let constraints = [
            icon.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10),
            icon.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            icon.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            icon.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            bottomAnchor.constraint(greaterThanOrEqualTo: icon.bottomAnchor, constant: 10),

            contentStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 11),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: contentStack.bottomAnchor, constant: 11),
            chevron.leadingAnchor.constraint(equalTo: contentStack.trailingAnchor, constant: 12),

            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: chevron.trailingAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    public override var isHighlighted: Bool {
        get { super.isHighlighted }
        set {
            super.isHighlighted = newValue
            if newValue {
                backgroundColor = Asset.Colors.selectionHighlight.color
            } else {
                backgroundColor = .clear
            }
        }
    }
}
