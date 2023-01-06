//
//  ProfileCardView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import os.log
import UIKit
import Combine
import Meta
import AlamofireImage
import CoreDataStack
import MastodonLocalization
import MastodonAsset
import MastodonSDK
import MastodonCore

extension ProfileCardView {
    public class ViewModel: ObservableObject {
        let logger = Logger(subsystem: "ProfileCardView", category: "ViewModel")
        var disposeBag = Set<AnyCancellable>()
        
        public let relationshipViewModel = RelationshipViewModel()
        
        @Published public var userInterfaceStyle: UIUserInterfaceStyle?
        @Published public var backgroundColor: UIColor?

        // Author
        @Published public var authorBannerImageURL: URL?
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?
        
        @Published public var bioContent: MetaContent?
        
        @Published public var statusesCount: Int?
        @Published public var followingCount: Int?
        @Published public var followersCount: Int?
                
        @Published public var isUpdating = false
        @Published public var isFollowedBy = false
        @Published public var isMuting = false
        @Published public var isBlocking = false
        @Published public var isBlockedBy = false

        @Published public var groupedAccessibilityLabel = ""
        
        @Published public var familiarFollowers: Mastodon.Entity.FamiliarFollowers?
        
        init() {
            backgroundColor = ThemeService.shared.currentTheme.value.systemBackgroundColor
            Publishers.CombineLatest(
                ThemeService.shared.currentTheme,
                $userInterfaceStyle
            )
            .sink { [weak self] theme, userInterfaceStyle in
                guard let self = self else { return }
                guard let userInterfaceStyle = userInterfaceStyle else { return }
                switch userInterfaceStyle {
                case .dark:
                    switch theme.themeName {
                    case .mastodon:
                        self.backgroundColor = theme.systemBackgroundColor
                    case .system:
                        self.backgroundColor = theme.secondarySystemBackgroundColor
                    }
                case .light, .unspecified:
                    self.backgroundColor = Asset.Scene.Discovery.profileCardBackground.color
                @unknown default:
                    self.backgroundColor = Asset.Scene.Discovery.profileCardBackground.color
                    assertionFailure()
                    // do nothing
                }
            }
            .store(in: &disposeBag)
        }
    }
}

extension ProfileCardView.ViewModel {
    func bind(view: ProfileCardView) {
        bindAppearacne(view: view)
        bindHeader(view: view)
        bindUser(view: view)
        bindBio(view: view)
        bindRelationship(view: view)
        bindDashboard(view: view)
        bindFamiliarFollowers(view: view)
        bindAccessibility(view: view)
    }
    
    private func bindAppearacne(view: ProfileCardView) {
        userInterfaceStyle = view.traitCollection.userInterfaceStyle
        
        $backgroundColor
            .assign(to: \.backgroundColor, on: view.container)
            .store(in: &disposeBag)
        $backgroundColor
            .assign(to: \.backgroundColor, on: view.avatarButtonBackgroundView)
            .store(in: &disposeBag)
    }
    
    
    private func bindHeader(view: ProfileCardView) {
        $authorBannerImageURL
            .sink { url in
                guard let url = url, !url.absoluteString.hasSuffix("missing.png") else {
                    view.bannerImageView.image = .placeholder(color: .systemGray3)
                    return
                }
                view.bannerImageView.af.setImage(
                    withURL: url,
                    placeholderImage: .placeholder(color: .systemGray3),
                    imageTransition: .crossDissolve(0.3)
                )
            }
            .store(in: &disposeBag)
    }
    
    private func bindUser(view: ProfileCardView) {
        $authorAvatarImageURL
            .sink { url in
                view.avatarButton.avatarImageView.configure(
                    configuration: .init(
                        url: url,
                        placeholder: .placeholder(color: .systemGray3)
                    )
                )
                view.avatarButton.avatarImageView.configure(
                    cornerConfiguration: .init(corner: .fixed(radius: 12))
                )
            }
            .store(in: &disposeBag)
        
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                view.authorNameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // username
        $authorUsername
            .map { text -> String in
                guard let text = text else { return "" }
                return "@\(text)"
            }
            .sink { username in
                let metaContent = PlaintextMetaContent(string: username)
                view.authorUsernameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
    }
    
    private func bindBio(view: ProfileCardView) {
        $bioContent
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                view.bioMetaText.configure(content: metaContent)
            }
            .store(in: &disposeBag)
    }
    
    private func bindRelationship(view: ProfileCardView) {
        relationshipViewModel.$optionSet
            .receive(on: DispatchQueue.main)
            .sink { relationshipActionSet in
                let relationshipActionSet = relationshipActionSet ?? .follow
                view.relationshipActionButton.configure(actionOptionSet: relationshipActionSet)
            }
            .store(in: &disposeBag)
    }
    
    private func bindDashboard(view: ProfileCardView) {
        relationshipViewModel.$isMyself
            .sink { isMyself in
                if isMyself {
                    view.statusDashboardView.postDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.myPosts
                    view.statusDashboardView.followingDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.myFollowing
                    view.statusDashboardView.followersDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.myFollowers
                } else {
                    view.statusDashboardView.postDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.otherPosts
                    view.statusDashboardView.followingDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.otherFollowing
                    view.statusDashboardView.followersDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.otherFollowers
                }
            }
            .store(in: &disposeBag)
        $statusesCount
            .receive(on: DispatchQueue.main)
            .sink { count in
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                view.statusDashboardView.postDashboardMeterView.numberLabel.text = text
                view.statusDashboardView.postDashboardMeterView.isAccessibilityElement = true
                view.statusDashboardView.postDashboardMeterView.accessibilityLabel = L10n.Plural.Count.post(count ?? 0)
            }
            .store(in: &disposeBag)
        $followingCount
            .receive(on: DispatchQueue.main)
            .sink { count in
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                view.statusDashboardView.followingDashboardMeterView.numberLabel.text = text
                view.statusDashboardView.followingDashboardMeterView.isAccessibilityElement = true
                view.statusDashboardView.followingDashboardMeterView.accessibilityLabel = L10n.Plural.Count.following(count ?? 0)
            }
            .store(in: &disposeBag)
        $followersCount
            .receive(on: DispatchQueue.main)
            .sink { count in
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                view.statusDashboardView.followersDashboardMeterView.numberLabel.text = text
                view.statusDashboardView.followersDashboardMeterView.isAccessibilityElement = true
                view.statusDashboardView.followersDashboardMeterView.accessibilityLabel = L10n.Plural.Count.follower(count ?? 0)
            }
            .store(in: &disposeBag)
    }
    
    private func bindFamiliarFollowers(view: ProfileCardView) {
        $familiarFollowers
            .sink { familiarFollowers in
                view.familiarFollowersDashboardViewAdaptiveMarginContainerView.isHidden = familiarFollowers.flatMap { $0.accounts.isEmpty } ?? true
                view.familiarFollowersDashboardView.configure(familiarFollowers: familiarFollowers)
            }
            .store(in: &disposeBag)
        $backgroundColor
            .assign(to: \.backgroundColor, on: view.familiarFollowersDashboardView.viewModel)
            .store(in: &disposeBag)
    }
    
    private func bindAccessibility(view: ProfileCardView) {
        let authorAccessibilityLabel = Publishers.CombineLatest(
            $authorName,
            $bioContent
        )
        .map { authorName, bioContent -> String? in
            var strings: [String?] = []
            strings.append(authorName?.string)
            strings.append(bioContent?.string)
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        
        authorAccessibilityLabel
            .map { $0 ?? "" }
            .assign(to: &$groupedAccessibilityLabel)
        
        $groupedAccessibilityLabel
            .sink { accessibilityLabel in
                view.accessibilityLabel = accessibilityLabel
            }
            .store(in: &disposeBag)
    }
}
