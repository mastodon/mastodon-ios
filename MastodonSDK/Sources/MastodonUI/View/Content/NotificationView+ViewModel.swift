//
//  NotificationView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-1-21.
//

import os.log
import UIKit
import Combine
import Meta
import MastodonSDK
import MastodonAsset
import MastodonLocalization
import MastodonExtension
import MastodonCore
import CoreData
import CoreDataStack

extension NotificationView {
    public final class ViewModel: ObservableObject {
        public var disposeBag = Set<AnyCancellable>()
        public var objects = Set<NSManagedObject>()

        let logger = Logger(subsystem: "NotificationView", category: "ViewModel")
        
        @Published public var authContext: AuthContext?
        
        @Published public var notificationIndicatorText: MetaContent?

        @Published public var authorAvatarImage: UIImage?
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?
        
        @Published public var isMyself = false
        @Published public var isMuting = false
        @Published public var isBlocking = false
        
        @Published public var timestamp: Date?
        
        @Published public var followRequestState = MastodonFollowRequestState(state: .none)
        @Published public var transientFollowRequestState = MastodonFollowRequestState(state: .none)
        
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
    }
}

extension NotificationView.ViewModel {
    func bind(notificationView: NotificationView) {
        bindAuthor(notificationView: notificationView)
        bindAuthorMenu(notificationView: notificationView)
        bindFollowRequest(notificationView: notificationView)
        
        $authContext
            .assign(to: \.authContext, on: notificationView.statusView.viewModel)
            .store(in: &disposeBag)
        $authContext
            .assign(to: \.authContext, on: notificationView.quoteStatusView.viewModel)
            .store(in: &disposeBag)
    }
 
    private func bindAuthor(notificationView: NotificationView) {
        // avatar
        Publishers.CombineLatest(
            $authorAvatarImage,
            $authorAvatarImageURL
        )
        .sink { image, url in
            let configuration: AvatarImageView.Configuration = {
                if let image = image {
                    return AvatarImageView.Configuration(image: image)
                } else {
                    return AvatarImageView.Configuration(url: url)
                }
            }()
            notificationView.avatarButton.avatarImageView.configure(configuration: configuration)
            notificationView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 12)))
        }
        .store(in: &disposeBag)
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                notificationView.authorNameLabel.configure(content: metaContent)
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
                notificationView.authorUsernameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // timestamp
        Publishers.CombineLatest(
            $timestamp,
            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
        )
        .sink { [weak self] timestamp, _ in
            guard let self = self else { return }
            guard let timestamp = timestamp else {
                notificationView.dateLabel.configure(content: PlaintextMetaContent(string: ""))
                return
            }
            
            let text = timestamp.localizedTimeAgoSinceNow
            notificationView.dateLabel.configure(content: PlaintextMetaContent(string: text))
        }
        .store(in: &disposeBag)
        // notification type indicator
        $notificationIndicatorText
            .sink { text in
                if let text = text {
                    notificationView.notificationTypeIndicatorLabel.configure(content: text)
                } else {
                    notificationView.notificationTypeIndicatorLabel.reset()
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindAuthorMenu(notificationView: NotificationView) {
        Publishers.CombineLatest4(
            $authorName,
            $isMuting,
            $isBlocking,
            $isMyself
        )
        .sink { authorName, isMuting, isBlocking, isMyself in
            guard let name = authorName?.string else {
                notificationView.menuButton.menu = nil
                return
            }
            
            let menuContext = NotificationView.AuthorMenuContext(
                name: name,
                isMuting: isMuting,
                isBlocking: isBlocking,
                isMyself: isMyself,
                isBookmarking: false    // no bookmark action display for notification item
            )
            notificationView.menuButton.menu = notificationView.setupAuthorMenu(menuContext: menuContext)
            notificationView.menuButton.showsMenuAsPrimaryAction = true
            
            notificationView.menuButton.isHidden = menuContext.isMyself
        }
        .store(in: &disposeBag)
    }
    
    private func bindFollowRequest(notificationView: NotificationView) {
        Publishers.CombineLatest(
            $followRequestState,
            $transientFollowRequestState
        )
        .sink { followRequestState, transientFollowRequestState in
            switch followRequestState.state {
            case .isAccept:
                notificationView.rejectFollowRequestButtonShadowBackgroundContainer.isHidden = true
                notificationView.acceptFollowRequestButton.isUserInteractionEnabled = false
                notificationView.acceptFollowRequestButton.setImage(nil, for: .normal)
                notificationView.acceptFollowRequestButton.setTitle(L10n.Scene.Notification.FollowRequest.accepted, for: .normal)
            case .isReject:
                notificationView.acceptFollowRequestButtonShadowBackgroundContainer.isHidden = true
                notificationView.rejectFollowRequestButton.isUserInteractionEnabled = false
                notificationView.rejectFollowRequestButton.setImage(nil, for: .normal)
                notificationView.rejectFollowRequestButton.setTitle(L10n.Scene.Notification.FollowRequest.rejected, for: .normal)
            default:
                break
            }
            
            let state = transientFollowRequestState.state
            if state == .isAccepting {
                notificationView.acceptFollowRequestActivityIndicatorView.startAnimating()
                notificationView.acceptFollowRequestButton.tintColor = .clear
                notificationView.acceptFollowRequestButton.setTitleColor(.clear, for: .normal)
            } else {
                notificationView.acceptFollowRequestActivityIndicatorView.stopAnimating()
                notificationView.acceptFollowRequestButton.tintColor = .white
                notificationView.acceptFollowRequestButton.setTitleColor(.white, for: .normal)
            }
            if state == .isRejecting {
                notificationView.rejectFollowRequestActivityIndicatorView.startAnimating()
                notificationView.rejectFollowRequestButton.tintColor = .clear
                notificationView.rejectFollowRequestButton.setTitleColor(.clear, for: .normal)
            } else {
                notificationView.rejectFollowRequestActivityIndicatorView.stopAnimating()
                notificationView.rejectFollowRequestButton.tintColor = .black
                notificationView.rejectFollowRequestButton.setTitleColor(.black, for: .normal)
            }
            
            UIView.animate(withDuration: 0.3) {
                if state == .isAccept {
                    notificationView.rejectFollowRequestButtonShadowBackgroundContainer.isHidden = true
                }
                if state == .isReject {
                    notificationView.acceptFollowRequestButtonShadowBackgroundContainer.isHidden = true
                }
            }
        }
        .store(in: &disposeBag)
    }
    
}
