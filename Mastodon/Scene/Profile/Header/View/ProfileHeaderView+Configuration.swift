//
//  ProfileHeaderView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-26.
//

import os.log
import UIKit
import Combine
import CoreDataStack

extension ProfileHeaderView {
    func configuration(user: MastodonUser) {
        // header
        user.publisher(for: \.header)
            .map { _ in user.headerImageURL() }
            .assign(to: \.headerImageURL, on: viewModel)
            .store(in: &disposeBag)
        // avatar
        user.publisher(for: \.avatar)
            .map { _ in user.avatarImageURL() }
            .assign(to: \.avatarImageURL, on: viewModel)
            .store(in: &disposeBag)
        // emojiMeta
        user.publisher(for: \.emojis)
            .map { $0.asDictionary }
            .assign(to: \.emojiMeta, on: viewModel)
            .store(in: &disposeBag)
        // name
        user.publisher(for: \.displayName)
            .map { _ in user.displayNameWithFallback }
            .assign(to: \.name, on: viewModel)
            .store(in: &disposeBag)
        // username
        viewModel.acct = user.acctWithDomain
        // bio
        user.publisher(for: \.note)
            .assign(to: \.note, on: viewModel)
            .store(in: &disposeBag)
        // dashboard
        user.publisher(for: \.statusesCount)
            .map { Int($0) }
            .assign(to: \.statusesCount, on: viewModel)
            .store(in: &disposeBag)
        user.publisher(for: \.followingCount)
            .map { Int($0) }
            .assign(to: \.followingCount, on: viewModel)
            .store(in: &disposeBag)
        user.publisher(for: \.followersCount)
            .map { Int($0) }
            .assign(to: \.followersCount, on: viewModel)
            .store(in: &disposeBag)
    }
}

