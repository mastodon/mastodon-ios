//
//  UserView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-1-19.
//

import CoreDataStack
import UIKit
import Combine
import MetaTextKit
import MastodonCore
import MastodonMeta
import MastodonAsset
import MastodonLocalization
import MastodonSDK

extension UserView {
    public final class ViewModel: ObservableObject {
        public var disposeBag = Set<AnyCancellable>()
        public var observations = Set<NSKeyValueObservation>()

        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?
        @Published public var authorFollowers: Int?
        @Published public var authorVerifiedLink: String?
        @Published public var account: Mastodon.Entity.Account?
        @Published public var relationship: Mastodon.Entity.Relationship?
    }
}

extension UserView.ViewModel {
    private static var metricFormatter = MastodonMetricFormatter()
    
    func bind(userView: UserView) {
        // avatar
        $authorAvatarImageURL
            .sink { url in
                userView.avatarButton.avatarImageView.configure(with: url)
                userView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 7)))
            }
            .store(in: &disposeBag)
        
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                userView.authorNameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // username
        let displayUsername = $authorUsername
            .map { text -> String in
                guard let text = text else { return "" }
                return "@\(text)"
            }

        displayUsername
            .sink { username in
                let metaContent = PlaintextMetaContent(string: username)
                userView.authorUsernameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest($authorName, displayUsername)
            .sink { name, username in
                if let name {
                    userView.accessibilityLabel = "\(name.string), \(username)"
                } else {
                    userView.accessibilityLabel = username
                }
            }
            .store(in: &disposeBag)
        
        $authorFollowers
            .sink { count in
                guard let count = count else {
                    userView.authorFollowersLabel.text = nil
                    return
                }
                userView.authorFollowersLabel.attributedText = NSAttributedString(
                    format: NSAttributedString(string: L10n.Common.UserList.followersCount("%@"), attributes: [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))]),
                    args: NSAttributedString(string: Self.metricFormatter.string(from: count) ?? count.formatted(), attributes: [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))])
                )
            }
            .store(in: &disposeBag)
        
        $authorVerifiedLink
            .sink { link in
                userView.authorVerifiedImageView.image = link == nil ? UIImage(systemName: "questionmark.circle") : UIImage(systemName: "checkmark")

                switch link {
                case let .some(link):
                    userView.authorVerifiedImageView.tintColor = Asset.Colors.Brand.blurple.color
                    userView.authorVerifiedLabel.textColor = Asset.Colors.Brand.blurple.color
                    do {
                        let mastodonContent = MastodonContent(content: link, emojis: [:])
                        let content = try MastodonMetaContent.convert(document: mastodonContent)
                        userView.authorVerifiedLabel.configure(content: content)
                    } catch {
                        let content = PlaintextMetaContent(string: link)
                        userView.authorVerifiedLabel.configure(content: content)
                    }
                case .none:
                    userView.authorVerifiedImageView.tintColor = .secondaryLabel
                    userView.authorVerifiedLabel.configure(content: PlaintextMetaContent(string: L10n.Common.UserList.noVerifiedLink))
                    userView.authorVerifiedLabel.textColor = .secondaryLabel
                }

            }
            .store(in: &disposeBag)
    }
}
