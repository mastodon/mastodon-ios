//
//  DataSourceFacade+Follow.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import CoreDataStack
import MastodonCore
import MastodonSDK
import MastodonLocalization

extension DataSourceFacade {
    @MainActor
    static func responseToUserFollowAction(
        dependency: UIViewController & AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        let authBox = dependency.authenticationBox
        let relationship = try await APIService.shared.relationship(
            forAccounts: [account], authenticationBox: authBox
        ).value.first
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let performAction = {
                    FeedbackGenerator.shared.generate(.selectionChanged)

                    do {
                        let response = try await APIService.shared.toggleFollow(
                            account: account,
                            authenticationBox: dependency.authenticationBox
                        ).value
                        
                        AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authBox.globallyUniqueUserIdentifier)
                        
                        
                        NotificationCenter.default.post(name: .relationshipChanged, object: nil, userInfo: [
                            UserInfoKey.relationship: response
                        ])
                        
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }

                if relationship?.following == true {
                    let alert = UIAlertController(
                        title: L10n.Common.Alerts.UnfollowUser.title("@\(account.username)"),
                        message: nil,
                        preferredStyle: .alert
                    )
                    let cancel = UIAlertAction(title: L10n.Common.Alerts.UnfollowUser.cancel, style: .default) { _ in
                        if let relationship {
                            NotificationCenter.default.post(name: .relationshipChanged, object: nil, userInfo: [
                                UserInfoKey.relationship: relationship
                            ])
                            
                            continuation.resume(returning: relationship)
                        } else {
                            continuation.resume(throwing: AppError.unexpected())
                        }
                    }
                    alert.addAction(cancel)
                    let unfollow = UIAlertAction(title: L10n.Common.Alerts.UnfollowUser.unfollow, style: .destructive) { _ in
                        Task {
                            await performAction()
                        }
                    }
                    alert.addAction(unfollow)
                    dependency.present(alert, animated: true)
                } else {
                    await performAction()
                }
            }
        }
    }

}

extension DataSourceFacade {
    static func responseToUserFollowRequestAction(
        dependency: UIViewController & AuthContextProvider,
        notification: MastodonNotification,
        notificationView: NotificationView,
        query: Mastodon.API.Account.FollowRequestQuery
    ) async throws {
        FeedbackGenerator.shared.generate(.selectionChanged)

        let userID = notification.account.id
        let state: MastodonFollowRequestState = notification.followRequestState
        
        guard state.state == .none else { return }

        switch query {
        case .accept:
            notification.transientFollowRequestState = .init(state: .isAccepting)
        case .reject:
            notification.transientFollowRequestState = .init(state: .isRejecting)
        }

        await notificationView.configure(notification: notification)

        do {
            let newRelationship = try await APIService.shared.followRequest(
                userID: userID,
                query: query,
                authenticationBox: dependency.authenticationBox
            ).value

            switch query {
            case .accept:
                notification.transientFollowRequestState = .init(state: .isAccept)
                notification.followRequestState = .init(state: .isAccept)
            case .reject:
                break
            }

            NotificationCenter.default.post(name: .relationshipChanged, object: nil, userInfo: [
                UserInfoKey.relationship: newRelationship
            ])

            await notificationView.configure(notification: notification)
        } catch {
            // reset state when failure
            notification.transientFollowRequestState = .init(state: .none)
            await notificationView.configure(notification: notification)

            if let error = error as? Mastodon.API.Error {
                switch error.httpResponseStatus {
                case .notFound:
                    break
                default:
                    guard let coordinator = await dependency.sceneCoordinator else { return }
                    let alertController = await UIAlertController(for: error, title: nil, preferredStyle: .alert)
                    let okAction = await UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default)
                    await alertController.addAction(okAction)
                    _ = await coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
            }
        }
        
    }
}

extension DataSourceFacade {
    static func responseToShowHideReblogAction(
        dependency: AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws {
        let newRelationship = try await APIService.shared.toggleShowReblogs(
            for: account,
            authenticationBox: dependency.authenticationBox
        )

        let userInfo = [
            UserInfoKey.relationship: newRelationship,
        ]

        NotificationCenter.default.post(name: .relationshipChanged, object: self, userInfo: userInfo)
    }
}
