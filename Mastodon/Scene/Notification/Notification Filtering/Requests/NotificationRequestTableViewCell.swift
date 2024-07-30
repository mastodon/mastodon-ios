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
    func acceptNotificationRequest(_ cell: NotificationRequestTableViewCell, notificationRequest: Mastodon.Entity.NotificationRequest)
    func rejectNotificationRequest(_ cell: NotificationRequestTableViewCell, notificationRequest: Mastodon.Entity.NotificationRequest)
}

class NotificationRequestTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NotificationRequestTableViewCell"

    var notificationRequest: Mastodon.Entity.NotificationRequest?
    weak var delegate: NotificationRequestTableViewCellDelegate?

    let nameLabel: MetaLabel
    let usernameLabel: MetaLabel
    let avatarButton: AvatarButton
    let chevronImageView: UIImageView

    private let labelStackView: UIStackView
    private let avatarStackView: UIStackView
    private let contentStackView: UIStackView

    let acceptNotificationRequestButtonShadowBackgroundContainer = ShadowBackgroundContainer()
    let acceptNotificationRequestButton: HighlightDimmableButton
    let acceptNotificationRequestActivityIndicatorView: UIActivityIndicatorView

    let rejectNotificationRequestButtonShadowBackgroundContainer = ShadowBackgroundContainer()
    let rejectNotificationRequestActivityIndicatorView: UIActivityIndicatorView
    let rejectNotificationRequestButton: HighlightDimmableButton

    let requestCountView: NotificationRequestCountView

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
        labelStackView.isUserInteractionEnabled = false
        
        acceptNotificationRequestButton = HighlightDimmableButton()
        acceptNotificationRequestButton.translatesAutoresizingMaskIntoConstraints = false
        acceptNotificationRequestButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        acceptNotificationRequestButton.setTitleColor(.white, for: .normal)
        acceptNotificationRequestButton.setTitle(L10n.Scene.Notification.FilteredNotification.accept, for: .normal)
        acceptNotificationRequestButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
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

        acceptNotificationRequestActivityIndicatorView = UIActivityIndicatorView(style: .medium)
        acceptNotificationRequestActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        acceptNotificationRequestActivityIndicatorView.color = .white
        acceptNotificationRequestActivityIndicatorView.hidesWhenStopped = true
        acceptNotificationRequestActivityIndicatorView.stopAnimating()
        acceptNotificationRequestButton.addSubview(acceptNotificationRequestActivityIndicatorView)

        rejectNotificationRequestButton = HighlightDimmableButton()
        rejectNotificationRequestButton.translatesAutoresizingMaskIntoConstraints = false
        rejectNotificationRequestButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        rejectNotificationRequestButton.setTitleColor(.black, for: .normal)
        rejectNotificationRequestButton.setTitle(L10n.Scene.Notification.FilteredNotification.dismiss, for: .normal)
        rejectNotificationRequestButton.setImage(NotificationRequestConstants.dismissIcon, for: .normal)
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

        rejectNotificationRequestActivityIndicatorView = UIActivityIndicatorView(style: .medium)
        rejectNotificationRequestActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        rejectNotificationRequestActivityIndicatorView.color = .black
        rejectNotificationRequestActivityIndicatorView.hidesWhenStopped = true
        rejectNotificationRequestActivityIndicatorView.stopAnimating()
        rejectNotificationRequestButton.addSubview(rejectNotificationRequestActivityIndicatorView)

        buttonStackView = UIStackView(arrangedSubviews: [rejectNotificationRequestButtonShadowBackgroundContainer, acceptNotificationRequestButtonShadowBackgroundContainer])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        buttonStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)  // set bottom padding

        chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .tertiaryLabel

        avatarStackView = UIStackView(arrangedSubviews: [avatarButton, labelStackView, UIView(), chevronImageView])
        avatarStackView.axis = .horizontal
        avatarStackView.alignment = .center
        avatarStackView.spacing = 12
        avatarStackView.isUserInteractionEnabled = false

        contentStackView = UIStackView(arrangedSubviews: [avatarStackView, buttonStackView])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.spacing = 16
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading

        requestCountView = NotificationRequestCountView()
        requestCountView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        acceptNotificationRequestButton.addTarget(self, action: #selector(NotificationRequestTableViewCell.acceptNotificationRequest(_:)), for: .touchUpInside)
        rejectNotificationRequestButton.addTarget(self, action: #selector(NotificationRequestTableViewCell.rejectNotificationRequest(_:)), for: .touchUpInside)

        contentView.addSubview(contentStackView)
        contentView.addSubview(requestCountView)
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

            acceptNotificationRequestActivityIndicatorView.centerXAnchor.constraint(equalTo: acceptNotificationRequestButton.centerXAnchor),
            acceptNotificationRequestActivityIndicatorView.centerYAnchor.constraint(equalTo: acceptNotificationRequestButton.centerYAnchor),
            rejectNotificationRequestActivityIndicatorView.centerXAnchor.constraint(equalTo: rejectNotificationRequestButton.centerXAnchor),
            rejectNotificationRequestActivityIndicatorView.centerYAnchor.constraint(equalTo: rejectNotificationRequestButton.centerYAnchor),

            requestCountView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: 2),
            requestCountView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 2),

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

        requestCountView.countLabel.text = request.notificationsCount
        requestCountView.setNeedsLayout()
        requestCountView.layoutIfNeeded()

        self.notificationRequest = request
    }

    // MARK: - Actions
    @objc private func acceptNotificationRequest(_ sender: UIButton) {
        guard let notificationRequest, let delegate else { return }

        delegate.acceptNotificationRequest(self, notificationRequest: notificationRequest)
    }
    @objc private func rejectNotificationRequest(_ sender: UIButton) {
        guard let notificationRequest, let delegate else { return }

        delegate.rejectNotificationRequest(self, notificationRequest: notificationRequest)
    }

}
