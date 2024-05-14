// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import MastodonAsset
import MastodonLocalization

class AccountWarningNotificationCell: UITableViewCell {
    public static let reuseIdentifier = "AccountWarningNotificationCell"

    let iconImageView: UIImageView
    let warningLabel: UILabel
    let learnMoreLabel: UILabel

    private let contentStackView: UIStackView
    private let labelStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let icon = UIImage(systemName: "exclamationmark.triangle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17)))
        iconImageView = UIImageView(image: icon)
        iconImageView.tintColor = Asset.Colors.Brand.blurple.color

        warningLabel = UILabel()
        warningLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17))
        warningLabel.numberOfLines = 0

        learnMoreLabel = UILabel()
        learnMoreLabel.text = L10n.Scene.Notification.Warning.learnMore
        learnMoreLabel.textColor = Asset.Colors.Brand.blurple.color
        learnMoreLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17))
        learnMoreLabel.numberOfLines = 0

        labelStackView = UIStackView(arrangedSubviews: [warningLabel, learnMoreLabel])
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading
        labelStackView.spacing = 7

        contentStackView = UIStackView(arrangedSubviews: [iconImageView, labelStackView])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.alignment = .top
        contentStackView.spacing = 16

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentStackView)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 16),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    public func configure(with accountWarning: Mastodon.Entity.AccountWarning) {
        warningLabel.text = accountWarning.action.description
    }
}

extension Mastodon.Entity.AccountWarning.Action {
    var description: String {
        switch self {
        case .none:
            return L10n.Scene.Notification.Warning.none
        case .disable:
            return L10n.Scene.Notification.Warning.disable
        case .markStatusesAsSensitive:
            return L10n.Scene.Notification.Warning.markStatusesAsSensitive
        case .deleteStatuses:
            return L10n.Scene.Notification.Warning.deleteStatuses
        case .sensitive:
            return L10n.Scene.Notification.Warning.sensitive
        case .silence:
            return L10n.Scene.Notification.Warning.silence
        case .suspend:
            return L10n.Scene.Notification.Warning.suspend
        }
    }
}
