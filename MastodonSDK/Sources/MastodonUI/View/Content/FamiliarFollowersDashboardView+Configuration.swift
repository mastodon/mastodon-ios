//
//  FamiliarFollowersDashboardView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import UIKit
import MastodonSDK

extension FamiliarFollowersDashboardView {
    public func configure(familiarFollowers: Mastodon.Entity.FamiliarFollowers?) {
        assert(Thread.isMainThread)
        
        let accounts = familiarFollowers?.accounts.prefix(4) ?? []
        
        viewModel.avatarURLs = accounts.map { $0.avatarImageURL() }
        viewModel.names = accounts.map { $0.displayNameWithFallback }
    }
}
