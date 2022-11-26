//
//  SuggestionAccountTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-16.
//

import UIKit
import Combine
import CoreDataStack
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonMeta
import Meta

extension SuggestionAccountTableViewCell {

    class ViewModel {
        var disposeBag = Set<AnyCancellable>()
        
        @Published public var userIdentifier: UserIdentifier?       // me
        
        @Published var avatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?
        
        @Published var isFollowing = false
        @Published var isPending = false
        
        func prepareForReuse() {
            isFollowing = false
            isPending = false
        }
    }

}

extension SuggestionAccountTableViewCell.ViewModel {
    func bind(cell: SuggestionAccountTableViewCell) {
        // avatar
        $avatarImageURL.removeDuplicates()
            .sink { url in
                let configuration = AvatarImageView.Configuration(url: url)
                cell.avatarButton.avatarImageView.configure(configuration: configuration)
                cell.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 12)))
            }
            .store(in: &disposeBag)
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                cell.titleLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // username
        $authorUsername
            .map { text -> String in
                guard let text = text else { return "" }
                return "@\(text)"
            }
            .sink { username in
                cell.subTitleLabel.text = username
            }
            .store(in: &disposeBag)
        // button
        Publishers.CombineLatest(
            $isFollowing,
            $isPending
        )
        .sink { isFollowing, isPending in
            let isFollowState = isFollowing || isPending
            let imageName = isFollowState ? "minus.circle.fill" : "plus.circle"
            let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))
            cell.button.setImage(image, for: .normal)
            cell.button.tintColor = isFollowState ? Asset.Colors.danger.color : Asset.Colors.Label.secondary.color
        }
        .store(in: &disposeBag)
    }
}

extension SuggestionAccountTableViewCell {
    func configure(user: MastodonUser) {
        // author avatar
        Publishers.CombineLatest(
            user.publisher(for: \.avatar),
            UserDefaults.shared.publisher(for: \.preferredStaticAvatar)
        )
        .map { _ in user.avatarImageURL() }
        .assign(to: \.avatarImageURL, on: viewModel)
        .store(in: &disposeBag)
        // author name
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
        // author username
        user.publisher(for: \.acct)
            .map { $0 as String? }
            .assign(to: \.authorUsername, on: viewModel)
            .store(in: &disposeBag)
        // isFollowing
        Publishers.CombineLatest(
            viewModel.$userIdentifier,
            user.publisher(for: \.followingBy)
        )
        .map { userIdentifier, followingBy in
            guard let userIdentifier = userIdentifier else { return false }
            return followingBy.contains(where: {
                $0.id == userIdentifier.userID && $0.domain == userIdentifier.domain
            })
        }
        .assign(to: \.isFollowing, on: viewModel)
        .store(in: &disposeBag)
        // isPending
        Publishers.CombineLatest(
            viewModel.$userIdentifier,
            user.publisher(for: \.followRequestedBy)
        )
        .map { userIdentifier, followRequestedBy in
            guard let userIdentifier = userIdentifier else { return false }
            return followRequestedBy.contains(where: {
                $0.id == userIdentifier.userID && $0.domain == userIdentifier.domain
            })
        }
        .assign(to: \.isPending, on: viewModel)
        .store(in: &disposeBag)
    }
}
