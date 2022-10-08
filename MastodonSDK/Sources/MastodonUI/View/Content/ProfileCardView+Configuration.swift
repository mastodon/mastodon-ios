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

    public func configure(user: MastodonUser) {
        // banner
        user.publisher(for: \.header)
            .map { URL(string: $0) }
            .assign(to: \.authorBannerImageURL, on: viewModel)
            .store(in: &disposeBag)
        // author avatar
        Publishers.CombineLatest3(
            user.publisher(for: \.avatar),
            user.publisher(for: \.avatarStatic),
            UserDefaults.shared.publisher(for: \.preferredStaticAvatar)
        )
        .map { _ in user.avatarImageURL() }
        .assign(to: \.authorAvatarImageURL, on: viewModel)
        .store(in: &disposeBag)
        // name
        Publishers.CombineLatest(
            user.publisher(for: \.displayName),
            user.publisher(for: \.emojis)
        )
        .map { _, emojis in
            do {
                let content = MastodonContent(content: user.displayNameWithFallback, emojis: emojis.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return PlaintextMetaContent(string: user.displayNameWithFallback)
            }
        }
        .assign(to: \.authorName, on: viewModel)
        .store(in: &disposeBag)
        // username
        user.publisher(for: \.acct)
            .map { $0 as String? }
            .assign(to: \.authorUsername, on: viewModel)
            .store(in: &disposeBag)
        // bio
        Publishers.CombineLatest(
            user.publisher(for: \.note),
            user.publisher(for: \.emojis)
        )
        .map { note, emojis in
            guard let note = note else { return nil }
            do {
                let content = MastodonContent(content: note, emojis: emojis.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
        .assign(to: \.bioContent, on: viewModel)
        .store(in: &disposeBag)
        // relationship
        viewModel.relationshipViewModel.user = user
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
