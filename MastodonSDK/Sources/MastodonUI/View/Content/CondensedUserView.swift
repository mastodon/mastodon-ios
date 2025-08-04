// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import CoreDataStack
import MetaTextKit
import MastodonAsset
import MastodonLocalization
import MastodonMeta
import MastodonCore
import MastodonSDK

public class CondensedUserView: UIView {
    private static var metricFormatter = MastodonMetricFormatter()

    private let avatarImageWrapperView: UIView
    let avatarImageView: AvatarImageView

    private let metaInformationStackView: UIStackView

    private let upperLineStackView: UIStackView
    let displayNameLabel: MetaLabel
    let acctLabel: UILabel

    private let lowerLineStackView: UIStackView
    let followersLabel: UILabel
    let verifiedLinkImageView: UIImageView
    let verifiedLinkLabel: MetaLabel

    private let contentStackView: UIStackView

    public override init(frame: CGRect) {
        avatarImageView = AvatarImageView()
        avatarImageView.avatarCornerConfiguration = AvatarImageView.CornerConfiguration(corner: .fixed(radius: 8))
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        avatarImageWrapperView = UIView()
        avatarImageWrapperView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageWrapperView.addSubview(avatarImageView)

        displayNameLabel = MetaLabel(style: .statusName)
        displayNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        displayNameLabel.setContentHuggingPriority(.required, for: .horizontal)

        acctLabel = UILabel()
        acctLabel.textColor = .secondaryLabel
        acctLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        acctLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        upperLineStackView = UIStackView(arrangedSubviews: [displayNameLabel, acctLabel])
        upperLineStackView.distribution = .fill
        upperLineStackView.alignment = .center

        followersLabel = UILabel()
        followersLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        followersLabel.textColor = .secondaryLabel
        followersLabel.setContentHuggingPriority(.required, for: .horizontal)

        verifiedLinkImageView = UIImageView()
        verifiedLinkImageView.setContentCompressionResistancePriority(.defaultHigh - 1, for: .vertical)
        verifiedLinkImageView.setContentHuggingPriority(.required, for: .horizontal)
        verifiedLinkImageView.contentMode = .scaleAspectFit

        verifiedLinkLabel = MetaLabel(style: .profileFieldValue)
        verifiedLinkLabel.setContentCompressionResistancePriority(.defaultHigh - 2, for: .horizontal)
        verifiedLinkLabel.translatesAutoresizingMaskIntoConstraints = false
        verifiedLinkLabel.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular)),
            .foregroundColor: UIColor.secondaryLabel
        ]
        verifiedLinkLabel.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular)),
            .foregroundColor: Asset.Colors.Brand.blurple.color
        ]
        verifiedLinkLabel.isUserInteractionEnabled = false

        lowerLineStackView = UIStackView(arrangedSubviews: [followersLabel, verifiedLinkImageView, verifiedLinkLabel])
        lowerLineStackView.distribution = .fill
        lowerLineStackView.alignment = .center
        lowerLineStackView.spacing = 4
        lowerLineStackView.setCustomSpacing(2, after: verifiedLinkImageView)

        metaInformationStackView = UIStackView(arrangedSubviews: [upperLineStackView, lowerLineStackView])
        metaInformationStackView.axis = .vertical
        metaInformationStackView.alignment = .leading

        contentStackView = UIStackView(arrangedSubviews: [avatarImageWrapperView, metaInformationStackView])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 16

        super.init(frame: .zero)

        addSubview(contentStackView)
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(greaterThanOrEqualTo: contentStackView.trailingAnchor, constant: 16),
            bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 8),

            upperLineStackView.trailingAnchor.constraint(greaterThanOrEqualTo: metaInformationStackView.trailingAnchor),
            lowerLineStackView.trailingAnchor.constraint(greaterThanOrEqualTo: metaInformationStackView.trailingAnchor),
            metaInformationStackView.trailingAnchor.constraint(greaterThanOrEqualTo: contentStackView.trailingAnchor),

            avatarImageView.widthAnchor.constraint(equalToConstant: 30),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),
            avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: avatarImageWrapperView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarImageWrapperView.leadingAnchor),
            avatarImageWrapperView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            avatarImageWrapperView.bottomAnchor.constraint(greaterThanOrEqualTo: avatarImageView.bottomAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarImageWrapperView.centerYAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    public func prepareForReuse() {
        avatarImageView.prepareForReuse()
    }

    public func configure(with account: Mastodon.Entity.Account, showFollowers: Bool = true) {
        let displayNameMetaContent: MetaContent
        do {
            let content = MastodonContent(content: account.displayNameWithFallback, emojis: account.emojis.asDictionary)
            displayNameMetaContent = try MastodonMetaContent.convert(document: content)
        } catch {
            displayNameMetaContent = PlaintextMetaContent(string: account.displayNameWithFallback)
        }

        displayNameLabel.configure(content: displayNameMetaContent)
        acctLabel.text = account.acct

        if showFollowers {
            followersLabel.attributedText = NSAttributedString(
                format: NSAttributedString(string: L10n.Common.UserList.followersCount("%@"), attributes: [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))]),
                args: NSAttributedString(string: Self.metricFormatter.string(from: account.followersCount) ?? account.followersCount.formatted(), attributes: [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))])
            )
            followersLabel.isHidden = false
        } else {
            followersLabel.isHidden = false
        }

        avatarImageView.setImage(url: account.avatarImageURL())

        if let verifiedLink = account.verifiedLink?.value {
            verifiedLinkImageView.image = UIImage(systemName: "checkmark")
            verifiedLinkImageView.tintColor = Asset.Colors.Brand.blurple.color

            let verifiedLinkMetaContent: MetaContent
            do {
                let mastodonContent = MastodonContent(content: verifiedLink, emojis: [:])
                verifiedLinkMetaContent = try MastodonMetaContent.convert(document: mastodonContent)
            } catch {
                verifiedLinkMetaContent = PlaintextMetaContent(string: verifiedLink)
            }

            verifiedLinkLabel.configure(content: verifiedLinkMetaContent)
        } else {
            verifiedLinkImageView.image = UIImage(systemName: "questionmark.circle")
            verifiedLinkImageView.tintColor = .secondaryLabel

            verifiedLinkLabel.configure(content: PlaintextMetaContent(string: L10n.Common.UserList.noVerifiedLink))
        }
    }

}
