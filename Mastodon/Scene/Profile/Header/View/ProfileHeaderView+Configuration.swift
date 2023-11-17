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
    func configuration(user: Mastodon.Entity.Account) {
        // header
        viewModel.headerImageURL = URL(string: user.header)
        
        // avatar
        viewModel.avatarImageURL = user.avatarImageURL()
        
        // emojiMeta
        viewModel.emojiMeta = user.emojiMeta
        
        // name
        viewModel.name = user.displayNameWithFallback
        
        // username
        viewModel.acct = user.acctWithDomain
        // bio
        viewModel.note = user.note
        
        // dashboard
        viewModel.statusesCount = user.statusesCount
        
        viewModel.followingCount = user.followingCount
        
        viewModel.followersCount = user.followersCount
    }
}

