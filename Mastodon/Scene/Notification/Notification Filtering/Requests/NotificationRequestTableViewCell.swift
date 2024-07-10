// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import MetaTextKit
import MastodonMeta
import MastodonUI
import MastodonCore

class NotificationRequestTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NotificationRequestTableViewCell"

    let nameLabel: MetaLabel
    let usernameLabel: MetaLabel
    let avatarButton: AvatarButton

    private let labelStackView: UIStackView
    private let contentStackView: UIStackView

//    private let stack
    // accept/deny-button

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

        contentStackView = UIStackView(arrangedSubviews: [avatarButton, labelStackView])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 12

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

            avatarButton.widthAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.width).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.height).priority(.required - 1),
        ]
        NSLayoutConstraint.activate(constraints)

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
}
