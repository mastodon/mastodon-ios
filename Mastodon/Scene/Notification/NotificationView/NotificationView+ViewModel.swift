//
//  NotificationView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-1-21.
//

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
import MastodonUI

extension NotificationView {
    public final class ViewModel: ObservableObject {
        public var disposeBag = Set<AnyCancellable>()

        @Published public var authContext: AuthContext?

        @Published public var type: MastodonNotificationType?
        @Published public var notificationIndicatorText: MetaContent?

        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?

        @Published public var timestamp: Date?

        @Published public var followRequestState = MastodonFollowRequestState(state: .none)
        @Published public var transientFollowRequestState = MastodonFollowRequestState(state: .none)
    }
}

extension NotificationView.ViewModel {
    func bind(notificationView: NotificationView) {
        $authContext
            .assign(to: \.authContext, on: notificationView.statusView.viewModel)
            .store(in: &disposeBag)
        $authContext
            .assign(to: \.authContext, on: notificationView.quoteStatusView.viewModel)
            .store(in: &disposeBag)
    }
 
    private func bindAuthor(notificationView: NotificationView) {
        // timestamp
        Publishers.CombineLatest4(
            $authorName,
            $authorUsername,
            $notificationIndicatorText,
            $timestamp
        )
        .sink { name, username, type, timestamp in

            let formattedTimestamp = timestamp?.localizedSlowedTimeAgoSinceNow ?? ""
            notificationView.accessibilityLabel = [
                "\(name?.string ?? "") \(type?.string ?? "")",
                username.map { "@\($0)" } ?? "",
                formattedTimestamp
            ].joined(separator: ", ")
            if !notificationView.statusView.isHidden {
                notificationView.accessibilityLabel! += ", " + (notificationView.statusView.accessibilityLabel ?? "")
            }
            if !notificationView.quoteStatusViewContainerView.isHidden {
                notificationView.accessibilityLabel! += ", " + (notificationView.quoteStatusView.accessibilityLabel ?? "")
            }
        }
        .store(in: &disposeBag)

            $type
        .sink { type in
            var actions = [UIAccessibilityCustomAction]()

            // these notifications can be directly actioned to view the profile
            if type != .follow, type != .followRequest {
                actions.append(
                    UIAccessibilityCustomAction(
                        name: L10n.Common.Controls.Status.showUserProfile,
                        image: nil
                    ) { [weak notificationView] _ in
                        guard let notificationView = notificationView, let delegate = notificationView.delegate else { return false }
                        delegate.notificationView(notificationView, authorAvatarButtonDidPressed: notificationView.avatarButton)
                        return true
                    }
                )
            }

            if type == .followRequest {
                actions.append(
                    UIAccessibilityCustomAction(
                        name: L10n.Common.Controls.Actions.confirm,
                        image: Asset.Editing.checkmark20.image
                    ) { [weak notificationView] _ in
                        guard let notificationView = notificationView, let delegate = notificationView.delegate else { return false }
                        delegate.notificationView(notificationView, acceptFollowRequestButtonDidPressed: notificationView.acceptFollowRequestButton)
                        return true
                    }
                )

                actions.append(
                    UIAccessibilityCustomAction(
                        name: L10n.Common.Controls.Actions.delete,
                        image: Asset.Circles.forbidden20.image
                    ) { [weak notificationView] _ in
                        guard let notificationView = notificationView, let delegate = notificationView.delegate else { return false }
                        delegate.notificationView(notificationView, rejectFollowRequestButtonDidPressed: notificationView.rejectFollowRequestButton)
                        return true
                    }
                )
            }

            notificationView.notificationActions = actions
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

