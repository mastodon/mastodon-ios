//
//  ProfileHeaderView+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-26.
//

import UIKit
import Combine
import CoreDataStack
import MetaTextKit
import MastodonMeta
import MastodonCore
import MastodonUI
import MastodonAsset
import MastodonLocalization
import MastodonSDK

extension ProfileHeaderView {
    class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        let viewDidAppear = PassthroughSubject<Void, Never>()
        
        @Published var state: State?
        @Published var isEditing = false
        @Published var isUpdating = false
        
        @Published var emojiMeta: MastodonContent.Emojis = [:]
        @Published var headerImageURL: URL?
        @Published var headerImageEditing: UIImage?
        @Published var avatarImageURL: URL?
        @Published var avatarImageEditing: UIImage?
        
        @Published var name: String?
        @Published var nameEditing: String?
        
        @Published var acct: String?
        
        @Published var note: String?
        @Published var noteEditing: String?
        
        @Published var statusesCount: Int?
        @Published var followingCount: Int?
        @Published var followersCount: Int?
        
        @Published var fields: [MastodonField] = []
        
        @Published var me: Mastodon.Entity.Account
        @Published var account: Mastodon.Entity.Account
        @Published var relationship: Mastodon.Entity.Relationship?
        @Published var isMyself = false
        
        init(account: Mastodon.Entity.Account, me: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?) {
            self.account = account
            self.me = me
            self.relationship = relationship
        }
    }
}

extension ProfileHeaderView.ViewModel {

    func bind(view: ProfileHeaderView) {
        // header
        Publishers.CombineLatest4(
            $headerImageURL,
            $headerImageEditing,
            $isEditing,
            viewDidAppear
        )
        .sink { headerImageURL, headerImageEditing, isEditing, _ in
            view.bannerImageView.af.cancelImageRequest()
            let defaultPlaceholder = UIImage.placeholder(color: ProfileHeaderView.bannerImageViewPlaceholderColor)
            let placeholder = isEditing ? (headerImageEditing ?? defaultPlaceholder) : defaultPlaceholder
            guard let bannerImageURL = headerImageURL,
                  !isEditing || headerImageEditing == nil
            else {
                view.bannerImageView.image = placeholder
                return
            }
            view.bannerImageView.af.setImage(
                withURL: bannerImageURL,
                placeholderImage: placeholder,
                imageTransition: .crossDissolve(0.3),
                runImageTransitionIfCached: false,
                completion: { [weak view] response in
                    guard let view = view else { return }
                    guard let image = response.value else { return }
                    guard image.size.width > 1 && image.size.height > 1 else {
                        // restore to placeholder when image invalid
                        view.bannerImageView.image = placeholder
                        return
                    }
                }
            )
        }
        .store(in: &disposeBag)
        // follows you
        Publishers.CombineLatest($relationship, $isMyself)
            .map { relationship, isMyself in
                return (relationship?.followedBy ?? false) && (isMyself == false)
            }
            .receive(on: DispatchQueue.main)
            .sink { followsYou in
                view.followsYouBlurEffectView.isHidden = (followsYou == false)
            }
            .store(in: &disposeBag)

        // avatar
        Publishers.CombineLatest4(
            $avatarImageURL,
            $avatarImageEditing,
            $isEditing,
            viewDidAppear
        )
        .sink { avatarImageURL, avatarImageEditing, isEditing, _ in
            view.avatarButton.avatarImageView.image = avatarImageEditing
            view.avatarButton.avatarImageView.configure(configuration: .init(
                url: (!isEditing || avatarImageEditing == nil) ? avatarImageURL : nil
            ))
        }
        .store(in: &disposeBag)
        // blur for blocking & blockingBy
        $relationship
            .compactMap { relationship in
                guard let relationship else { return false }

                return relationship.blocking || relationship.blockedBy || relationship.domainBlocking
            }
            .sink { needsImageOverlayBlurred in
                UIView.animate(withDuration: 0.33) {
                    let bannerEffect: UIVisualEffect? = needsImageOverlayBlurred ? ProfileHeaderView.bannerImageViewOverlayBlurEffect : nil
                    view.bannerImageViewOverlayVisualEffectView.effect = bannerEffect
                    let avatarEffect: UIVisualEffect? = needsImageOverlayBlurred ? ProfileHeaderView.avatarImageViewOverlayBlurEffect : nil
                    view.avatarImageViewOverlayVisualEffectView.effect = avatarEffect
                }
            }
            .store(in: &disposeBag)
        // name
        Publishers.CombineLatest4(
            $isEditing.removeDuplicates(),
            $name.removeDuplicates(),
            $nameEditing.removeDuplicates(),
            $emojiMeta.removeDuplicates()
        )
        .sink { isEditing, name, nameEditing, emojiMeta in
            do {
                let mastodonContent = MastodonContent(content: name ?? " ", emojis: emojiMeta)
                let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                view.nameMetaText.configure(content: metaContent)
            } catch {
                assertionFailure()
            }
            view.nameTextField.text = isEditing ? nameEditing : name
        }
        .store(in: &disposeBag)
        // username
        $acct
            .map { acct in acct.flatMap { "@" + $0 } ?? " " }
            .sink(receiveValue: { acct in
                view.usernameButton.setTitle(acct, for: .normal)
            })
            .store(in: &disposeBag)
        // bio
        Publishers.CombineLatest4(
            $isEditing.removeDuplicates(),
            $emojiMeta.removeDuplicates(),
            $note.removeDuplicates(),
            $noteEditing.removeDuplicates()
        )
        .sink { isEditing, emojiMeta, note, noteEditing in
            view.bioMetaText.textView.isEditable = isEditing
            
            let metaContent: MetaContent = {
                if isEditing {
                    return PlaintextMetaContent(string: noteEditing ?? "")
                } else {
                    do {
                        let mastodonContent = MastodonContent(content: note ?? "", emojis: emojiMeta)
                        return try MastodonMetaContent.convert(document: mastodonContent)
                    } catch {
                        assertionFailure()
                        return PlaintextMetaContent(string: note ?? "")
                    }
                }
            }()
            
            guard metaContent.string != view.bioMetaText.textStorage.string else { return }
            view.bioMetaText.configure(content: metaContent)
        }
        .store(in: &disposeBag)

        Publishers.CombineLatest($relationship, $account)
            .compactMap { relationship, account in

                guard let relationship else { return nil }

                let isBlocking = relationship.blocking || relationship.domainBlocking
                let isBlockedBy = relationship.blockedBy
                let isSuspended = account.suspended ?? false

                let isNeedsHidden = isBlocking || isBlockedBy || isSuspended

                return isNeedsHidden
            }
            .receive(on: DispatchQueue.main)
            .sink { isNeedsHidden in
                view.bioMetaText.textView.isHidden = isNeedsHidden
            }
            .store(in: &disposeBag)

        // dashboard
        $isMyself
            .receive(on: DispatchQueue.main)
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
            .sink { count in
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                view.statusDashboardView.postDashboardMeterView.numberLabel.text = text
                view.statusDashboardView.postDashboardMeterView.isAccessibilityElement = true
                view.statusDashboardView.postDashboardMeterView.accessibilityLabel = L10n.Plural.Count.post(count ?? 0)
            }
            .store(in: &disposeBag)
        $followingCount
            .sink { count in
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                view.statusDashboardView.followingDashboardMeterView.numberLabel.text = text
                view.statusDashboardView.followingDashboardMeterView.isAccessibilityElement = true
                view.statusDashboardView.followingDashboardMeterView.accessibilityLabel = L10n.Plural.Count.following(count ?? 0)
            }
            .store(in: &disposeBag)
        $followersCount
            .sink { count in
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                view.statusDashboardView.followersDashboardMeterView.numberLabel.text = text
                view.statusDashboardView.followersDashboardMeterView.isAccessibilityElement = true
                view.statusDashboardView.followersDashboardMeterView.accessibilityLabel = L10n.Plural.Count.follower(count ?? 0)
            }
            .store(in: &disposeBag)
        $isEditing
            .sink { isEditing in
                let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
                animator.addAnimations {
                    view.statusDashboardView.alpha = isEditing ? 0.2 : 1.0
                }
                animator.startAnimation()
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest3(
            Publishers.CombineLatest3($me, $account, $relationship).eraseToAnyPublisher(),
            $isEditing,
            $isUpdating
        )
        .receive(on: DispatchQueue.main)
        .sink { tuple, isEditing, isUpdating in
            let (me, account, relationship) = tuple

            view.relationshipActionButton.configure(relationship: relationship, between: account, and: me, isEditing: isEditing, isUpdating: isUpdating)
            view.configure(state: isEditing ? .editing : .normal)
        }
        .store(in: &disposeBag)
    }

}


extension ProfileHeaderView {
    enum State {
        case normal
        case editing
    }
    
    func configure(state: State) {
        guard viewModel.state != state else { return }   // avoid redundant animation
        viewModel.state = state
        
        let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
        
        switch state {
        case .normal:
            nameMetaText.textView.alpha = 1
            nameTextField.alpha = 0
            nameTextField.isEnabled = false
            bioMetaText.textView.backgroundColor = .clear

            animator.addAnimations {
                self.bannerImageViewOverlayVisualEffectView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundNormalColor
                self.nameTextFieldBackgroundView.backgroundColor = .clear
                self.editBannerButton.alpha = 0
                self.editAvatarBackgroundView.alpha = 0
            }
            animator.addCompletion { _ in
                self.editBannerButton.isHidden = true
                self.editAvatarBackgroundView.isHidden = true
                self.bannerImageViewSingleTapGestureRecognizer.isEnabled = true
            }
        case .editing:
            nameMetaText.textView.alpha = 0
            nameTextField.isEnabled = true
            nameTextField.alpha = 1
            
            editBannerButton.isHidden = false
            editBannerButton.alpha = 0
            editAvatarBackgroundView.isHidden = false
            editAvatarBackgroundView.alpha = 0
            bioMetaText.textView.backgroundColor = .clear
            bannerImageViewSingleTapGestureRecognizer.isEnabled = false
            animator.addAnimations {
                self.bannerImageViewOverlayVisualEffectView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundEditingColor
                self.nameTextFieldBackgroundView.backgroundColor = Asset.Scene.Profile.Banner.nameEditBackgroundGray.color
                self.editBannerButton.alpha = 1
                self.editAvatarBackgroundView.alpha = 1
                self.bioMetaText.textView.backgroundColor = Asset.Scene.Profile.Banner.bioEditBackgroundGray.color
            }
        }
        
        animator.startAnimation()
    }
}
