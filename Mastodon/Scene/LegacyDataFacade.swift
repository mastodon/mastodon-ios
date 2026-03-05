// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import MastodonCore
import UIKit
import MastodonLocalization
import MastodonUI

@MainActor
struct LegacyDataSourceFacade {
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
    
    static func responseToUserMuteAction(
        dependency: AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        FeedbackGenerator.shared.generate(.selectionChanged)
        
        let response = try await APIService.shared.toggleMute(
            authenticationBox: dependency.authenticationBox,
            account: account
        )
        
        let userInfo = [
            UserInfoKey.relationship: response.value,
        ]
        
        NotificationCenter.default.post(name: .relationshipChanged, object: self, userInfo: userInfo)
        
        return response.value
    }
    
    static func responseToUserBlockAction(
        dependency: AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        FeedbackGenerator.shared.generate(.selectionChanged)
        
        let apiService = APIService.shared
        let authBox = dependency.authenticationBox
        
        let response = try await apiService.toggleBlock(
            account: account,
            authenticationBox: authBox
        )
        
        let userInfo = [
            UserInfoKey.relationship: response.value,
        ]
        
        NotificationCenter.default.post(name: .relationshipChanged, object: self, userInfo: userInfo)
        
        return response.value
    }
    
    static func responseToDomainBlockAction(
        dependency: AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Empty {
        FeedbackGenerator.shared.generate(.selectionChanged)
        
        let apiService = APIService.shared
        let authBox = dependency.authenticationBox
        
        let response = try await apiService.toggleDomainBlock(account: account, authenticationBox: authBox)
        
        return response.value
    }
    
    static func responseToCreateSearchHistory(
        provider: UIViewController & AuthContextProvider,
        item: DataSourceItem
    ) async {
        switch item {
        case .account(account: let account, relationship: _):
            let now = Date()
            let userID = provider.authenticationBox.userID
            let searchEntry = Persistence.SearchHistory.Item(
                updatedAt: now,
                userID: userID,
                account: account,
                hashtag: nil
            )
            
            try? FileManager.default.addSearchItem(searchEntry, for: provider.authenticationBox)
        case .hashtag(let tag):
            
            let now = Date()
            let userID = provider.authenticationBox.userID
            let searchEntry = Persistence.SearchHistory.Item(
                updatedAt: now,
                userID: userID,
                account: nil,
                hashtag: tag
            )
            
            try? FileManager.default.addSearchItem(searchEntry, for: provider.authenticationBox)
        case .status, .notification, .notificationBanner(_):
            break
            
        }
    }
    
    enum DataSourceItem: Hashable {
        case status(record: MastodonStatus)
        case hashtag(tag: Mastodon.Entity.Tag)
        case notification(record: MastodonNotification)
        case notificationBanner(policy: Mastodon.Entity.NotificationPolicy)
        case account(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)
   
        struct Source {
            let collectionViewCell: UICollectionViewCell?
            let tableViewCell: UITableViewCell?
            let indexPath: IndexPath?
            
            init(
                collectionViewCell: UICollectionViewCell? = nil,
                tableViewCell: UITableViewCell? = nil,
                indexPath: IndexPath? = nil
            ) {
                self.collectionViewCell = collectionViewCell
                self.tableViewCell = tableViewCell
                self.indexPath = indexPath
            }
        }
    }
    
    static func coordinateToHashtagScene(
        provider: UIViewController,
        tag: Mastodon.Entity.Tag
    ) async {
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
        guard let coordinator = provider.sceneCoordinator else { return }
        _ = coordinator.present(
            scene: .hashtagTimeline(tag),
            from: provider,
            transition: .show
        )
    }

    static func responseToUserViewButtonAction(
        dependency: UIViewController & AuthContextProvider,
        account: Mastodon.Entity.Account,
        buttonState: UserView.ButtonState
    ) async throws -> Mastodon.Entity.Relationship? {
        switch buttonState {
        case .follow, .request, .unfollow, .blocked, .pending:
            return try await LegacyDataSourceFacade.responseToUserFollowAction(
                dependency: dependency,
                account: account
            )
        case .none, .loading:
            return nil
        }
    }
}
