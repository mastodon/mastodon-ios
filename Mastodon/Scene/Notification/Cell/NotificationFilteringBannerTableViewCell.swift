// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import MastodonUI

class NotificationFilteringBannerTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "NotificationFilteringBannerTableViewCell"

    let iconImageView: UIImageView
    let iconImageWrapperView: UIView

    let titleLabel: UILabel
    let subtitleLabel: UILabel
    private let contentStackView: UIStackView
    private let labelStackView: UIStackView
    let separatorLine: UIView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        let iconConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let icon = UIImage(systemName: "archivebox", withConfiguration: iconConfiguration)
        iconImageView = UIImageView(image: icon)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        iconImageWrapperView = UIView()
        iconImageWrapperView.translatesAutoresizingMaskIntoConstraints = false
        iconImageWrapperView.addSubview(iconImageView)

        titleLabel = UILabel()
        //TODO: Add localization
        titleLabel.text = "Filtered Notifications"
        titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))

        subtitleLabel = UILabel()
        subtitleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        subtitleLabel.textColor = .secondaryLabel


        labelStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical

        contentStackView = UIStackView(arrangedSubviews: [iconImageWrapperView,  labelStackView])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.alignment = .center
        contentStackView.axis = .horizontal
        contentStackView.spacing = 12

        separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentStackView)
        contentView.addSubview(separatorLine)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [

            iconImageWrapperView.widthAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.width),
            iconImageWrapperView.heightAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.height).priority(.defaultHigh),
            iconImageView.centerXAnchor.constraint(equalTo: iconImageWrapperView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconImageWrapperView.centerYAnchor),

            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 16),
            separatorLine.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 7),

            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView))
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func configure(with policy: Mastodon.Entity.NotificationPolicy) {
        //TODO: Add localization
        subtitleLabel.text = "\(policy.summary.pendingRequestsCount) people you may know"
    }
}
