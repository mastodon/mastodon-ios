// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import MetaTextKit
import MastodonMeta
import MastodonUI
import MastodonCore
import MastodonLocalization
import MastodonAsset

protocol NotificationRequestTableViewCellDelegate: AnyObject {
    // reject
    // accept
}

class NotificationRequestTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NotificationRequestTableViewCell"

    let nameLabel: MetaLabel
    let usernameLabel: MetaLabel
    let avatarButton: AvatarButton

    private let labelStackView: UIStackView
    private let avatarStackView: UIStackView
    private let contentStackView: UIStackView

//    private let stack
    // accept/deny-button

    let acceptNotificationRequestButtonShadowBackgroundContainer = ShadowBackgroundContainer()
    let acceptNotificationRequestButton: HighlightDimmableButton
    let acceptNotificationRequestActivityIndicatorView = UIActivityIndicatorView(style: .medium)

    let rejectNotificationRequestButtonShadowBackgroundContainer = ShadowBackgroundContainer()
    let rejectNotificationRequestActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let rejectNotificationRequestButton: HighlightDimmableButton

    private let buttonStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        nameLabel = MetaLabel(style: .statusName)
        usernameLabel = MetaLabel(style: .statusUsername)
        avatarButton = AvatarButton()
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.size = CGSize.authorAvatarButtonSize
        avatarButton.avatarImageView.imageViewSize = CGSize.authorAvatarButtonSize

        labelStackView = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading
        labelStackView.spacing = 4

        acceptNotificationRequestButton = HighlightDimmableButton()
        acceptNotificationRequestButton.translatesAutoresizingMaskIntoConstraints = false
        acceptNotificationRequestButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        acceptNotificationRequestButton.setTitleColor(.white, for: .normal)
        acceptNotificationRequestButton.setTitle(L10n.Common.Controls.Actions.confirm, for: .normal)
        acceptNotificationRequestButton.setImage(Asset.Editing.checkmark20.image.withRenderingMode(.alwaysTemplate), for: .normal)
        acceptNotificationRequestButton.imageView?.contentMode = .scaleAspectFit
        acceptNotificationRequestButton.setBackgroundImage(.placeholder(color: Asset.Scene.Notification.confirmFollowRequestButtonBackground.color), for: .normal)
        acceptNotificationRequestButton.setInsets(forContentPadding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), imageTitlePadding: 8)
        acceptNotificationRequestButton.tintColor = .white
        acceptNotificationRequestButton.layer.masksToBounds = true
        acceptNotificationRequestButton.layer.cornerCurve = .continuous
        acceptNotificationRequestButton.layer.cornerRadius = 10
        acceptNotificationRequestButton.accessibilityLabel = L10n.Scene.Notification.FollowRequest.accept
        acceptNotificationRequestButtonShadowBackgroundContainer.cornerRadius = 10
        acceptNotificationRequestButtonShadowBackgroundContainer.shadowAlpha = 0.1
        acceptNotificationRequestButtonShadowBackgroundContainer.addSubview(acceptNotificationRequestButton)

        rejectNotificationRequestButton = HighlightDimmableButton()
        rejectNotificationRequestButton.translatesAutoresizingMaskIntoConstraints = false
        rejectNotificationRequestButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        rejectNotificationRequestButton.setTitleColor(.black, for: .normal)
        rejectNotificationRequestButton.setTitle(L10n.Common.Controls.Actions.delete, for: .normal)
        rejectNotificationRequestButton.setImage(Asset.Circles.forbidden20.image.withRenderingMode(.alwaysTemplate), for: .normal)
        rejectNotificationRequestButton.imageView?.contentMode = .scaleAspectFit
        rejectNotificationRequestButton.setInsets(forContentPadding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), imageTitlePadding: 8)
        rejectNotificationRequestButton.setBackgroundImage(.placeholder(color: Asset.Scene.Notification.deleteFollowRequestButtonBackground.color), for: .normal)
        rejectNotificationRequestButton.tintColor = .black
        rejectNotificationRequestButton.layer.masksToBounds = true
        rejectNotificationRequestButton.layer.cornerCurve = .continuous
        rejectNotificationRequestButton.layer.cornerRadius = 10
        rejectNotificationRequestButton.accessibilityLabel = L10n.Scene.Notification.FollowRequest.reject
        rejectNotificationRequestButtonShadowBackgroundContainer.cornerRadius = 10
        rejectNotificationRequestButtonShadowBackgroundContainer.shadowAlpha = 0.1
        rejectNotificationRequestButtonShadowBackgroundContainer.addSubview(rejectNotificationRequestButton)

        buttonStackView = UIStackView(arrangedSubviews: [acceptNotificationRequestButtonShadowBackgroundContainer, rejectNotificationRequestButtonShadowBackgroundContainer])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        buttonStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)  // set bottom padding

        avatarStackView = UIStackView(arrangedSubviews: [avatarButton, labelStackView])
        avatarStackView.axis = .horizontal
        avatarStackView.alignment = .center
        avatarStackView.spacing = 12

        contentStackView = UIStackView(arrangedSubviews: [avatarStackView, buttonStackView])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.spacing = 16
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading

        super.init(style: style, reuseIdentifier: reuseIdentifier)

//        acceptNotificationRequestButton.addTarget(self, action: #selector(NotificationView.acceptNotificationRequestButtonDidPressed(_:)), for: .touchUpInside)
//        rejectNotificationRequestButton.addTarget(self, action: #selector(NotificationView.rejectNotificationRequestButtonDidPressed(_:)), for: .touchUpInside)

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

            buttonStackView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            avatarStackView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),

            avatarButton.widthAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.width).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.height).priority(.required - 1),
        ]
        NSLayoutConstraint.activate(constraints)

        acceptNotificationRequestButton.pinToParent()
        rejectNotificationRequestButton.pinToParent()
    }

    override func prepareForReuse() {
        avatarButton.avatarImageView.image = nil
        avatarButton.avatarImageView.cancelTask()
    }

    func configure(with request: Mastodon.Entity.NotificationRequest) {
        let account = request.account

        avatarButton.avatarImageView.configure(with: account.avatarImageURL())
        avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 12)))

        // author name
        let metaAccountName: MetaContent
        do {
            let content = MastodonContent(content: account.displayNameWithFallback, emojis: account.emojis.asDictionary)
            metaAccountName = try MastodonMetaContent.convert(document: content)
        } catch {
            assertionFailure(error.localizedDescription)
            metaAccountName = PlaintextMetaContent(string: account.displayNameWithFallback)
        }
        nameLabel.configure(content: metaAccountName)

        let metaUsername = PlaintextMetaContent(string: "@\(account.acct)")
        usernameLabel.configure(content: metaUsername)
    }

    // MARK: - Actions
    // reject
    // accept
}
