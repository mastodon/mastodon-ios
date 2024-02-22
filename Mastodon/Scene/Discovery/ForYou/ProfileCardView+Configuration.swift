//
//  ProfileCardView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import Foundation
import Combine
import CoreDataStack
import Meta
import MastodonCore
import MastodonMeta
import MastodonSDK

extension ProfileCardView {

    public func configure(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?) {
        viewModel.authorBannerImageURL = URL(string: account.header)
        viewModel.statusesCount = account.statusesCount
        viewModel.followingCount = account.followingCount
        viewModel.followersCount = account.followersCount
        viewModel.authorAvatarImageURL = account.avatarImageURL()

        let emojis = account.emojis.asDictionary

        do {
            let content = MastodonContent(content: account.displayNameWithFallback, emojis: emojis)
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.authorName = metaContent
        } catch {
            assertionFailure(error.localizedDescription)
            let metaContent = PlaintextMetaContent(string: account.displayNameWithFallback)
            viewModel.authorName = metaContent
        }

        viewModel.authorUsername = account.acct

        do {
            let content = MastodonContent(content: account.note, emojis: emojis)
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.bioContent = metaContent
        } catch {
            assertionFailure(error.localizedDescription)
            let metaContent = PlaintextMetaContent(string: account.note)
            viewModel.bioContent = metaContent
        }

        updateButtonState(with: relationship, isMe: false)
    }
}
