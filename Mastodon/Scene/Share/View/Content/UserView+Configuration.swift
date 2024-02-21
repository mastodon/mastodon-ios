//
//  UserView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import Combine
import MastodonUI
import CoreDataStack
import MastodonLocalization
import MastodonMeta
import MastodonCore
import Meta
import MastodonSDK
import MastodonAsset

extension UserView {
    func configure(with account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?, delegate: UserViewDelegate?) {
        viewModel.account = account
        viewModel.relationship = relationship
        self.delegate = delegate

        let authorUsername = PlaintextMetaContent(string: "@\(account.username)")
        authorUsernameLabel.configure(content: authorUsername)

        do {
            let emojis = account.emojis.asDictionary
            let content = MastodonContent(content: account.displayNameWithFallback, emojis: emojis)
            let metaContent = try MastodonMetaContent.convert(document: content)
            authorNameLabel.configure(content: metaContent)
        } catch {
            let metaContent = PlaintextMetaContent(string: account.displayNameWithFallback)
            authorNameLabel.configure(content: metaContent)
        }

        if let imageURL = account.avatarImageURL() {
            avatarButton.avatarImageView.af.setImage(withURL: imageURL)
        }

        let count = account.followersCount
        authorFollowersLabel.attributedText = NSAttributedString(
            format: NSAttributedString(string: L10n.Common.UserList.followersCount("%@"), attributes: [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))]),
            args: NSAttributedString(string: UserView.metricFormatter.string(from: count) ?? count.formatted(), attributes: [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))])
        )

        if let verifiedLinkField = account.verifiedLink {
            let link = verifiedLinkField.value

            authorVerifiedImageView.image = UIImage(systemName: "checkmark")
            authorVerifiedImageView.tintColor = Asset.Colors.Brand.blurple.color
            authorVerifiedLabel.textColor = Asset.Colors.Brand.blurple.color
            do {
                let mastodonContent = MastodonContent(content: link, emojis: [:])
                let content = try MastodonMetaContent.convert(document: mastodonContent)
                authorVerifiedLabel.configure(content: content)
            } catch {
                let content = PlaintextMetaContent(string: link)
                authorVerifiedLabel.configure(content: content)
            }
        } else {
            authorVerifiedImageView.image = UIImage(systemName: "questionmark.circle")
            authorVerifiedImageView.tintColor = .secondaryLabel
            authorVerifiedLabel.configure(content: PlaintextMetaContent(string: L10n.Common.UserList.noVerifiedLink))
            authorVerifiedLabel.textColor = .secondaryLabel
        }
    }
}
