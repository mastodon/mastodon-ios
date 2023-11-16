//
//  ProfileCardView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import Foundation
import Combine
import Meta
import MastodonCore
import MastodonMeta
import MastodonSDK

extension ProfileCardView {

    public func configure(user: Mastodon.Entity.Account) {
        // banner
        viewModel.authorBannerImageURL = URL(string: user.header)
        
        // author avatar
        viewModel.authorAvatarImageURL = user.avatarImageURL()
        
        // name
        viewModel.authorName = {
            do {
                let content = MastodonContent(content: user.displayNameWithFallback, emojis: user.emojis?.asDictionary ?? [:])
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return PlaintextMetaContent(string: user.displayNameWithFallback)
            }
        }()
        
        // username
        viewModel.authorUsername = user.acct
        
        // bio
        viewModel.bioContent = {
            guard !user.note.isEmpty else { return nil }
            do {
                let content = MastodonContent(content: user.note, emojis: user.emojis?.asDictionary ?? [:])
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        // relationship
        viewModel.relationshipViewModel.user = user
        
        // dashboard
        viewModel.statusesCount = user.statusesCount
        viewModel.followingCount = user.followingCount
        viewModel.followersCount = user.followersCount
    }
    
}
