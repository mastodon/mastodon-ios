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
