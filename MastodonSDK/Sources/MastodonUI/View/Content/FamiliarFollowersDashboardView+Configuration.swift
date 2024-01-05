//
//  FamiliarFollowersDashboardView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import UIKit
import MastodonSDK
import MastodonCore

extension FamiliarFollowersDashboardView {
    public func configure(familiarFollowers: Mastodon.Entity.FamiliarFollowers?) {
        assert(Thread.isMainThread)
        
        let accounts = familiarFollowers?.accounts ?? []
        
        viewModel.avatarURLs = accounts.map { $0.avatarImageURL() }
        viewModel.names = accounts.map { $0.displayNameWithFallback }
        viewModel.emojis = {
            var array: [Mastodon.Entity.Emoji] = []
            for account in accounts {
                array.append(contentsOf: account.emojis)
            }
            return array.asDictionary
        }()
    }
}
