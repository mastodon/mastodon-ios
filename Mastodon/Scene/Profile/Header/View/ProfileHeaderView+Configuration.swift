//
//  ProfileHeaderView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-26.
//

import UIKit
import Combine
import MastodonSDK

extension ProfileHeaderView {
    func configuration(account: Mastodon.Entity.Account) {
        viewModel.headerImageURL = account.headerImageURL()
        viewModel.avatarImageURL = account.avatarImageURL()
        viewModel.emojiMeta = account.emojiMeta
        viewModel.name = account.displayNameWithFallback
        viewModel.acct = account.acctWithDomain
        viewModel.note = account.note
        viewModel.statusesCount = account.statusesCount
        viewModel.followingCount = account.followingCount
        viewModel.followersCount = account.followersCount
    }
}

