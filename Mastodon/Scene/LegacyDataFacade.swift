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
        guard let relationship = try await APIService.shared.relationship(
            forAccounts: [account], authenticationBox: authBox
        )[account.id] else { throw AppError.unexpected() }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let performAction = {
                    FeedbackGenerator.shared.generate(.selectionChanged)
                    
                    do {
                        let response = try await {
                            if relationship.following == true {
                                return try await APIService.shared.unfollow(
                                    account.id,
                                    authenticationBox: dependency.authenticationBox
                                )
                            } else {
                                return try await APIService.shared.follow(
                                    account.id,
                                    authenticationBox: dependency.authenticationBox
                                )
                            }
                        }()
                        
                        
                        AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authBox.globallyUniqueUserIdentifier)
                        
                        
                        NotificationCenter.default.post(name: .relationshipChanged, object: nil, userInfo: [
                            UserInfoKey.relationship: response
                        ])
                        
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                
                if relationship.following == true {
                    let alert = UIAlertController(
                        title: L10n.Common.Alerts.UnfollowUser.title("@\(account.username)"),
                        message: nil,
                        preferredStyle: .alert
                    )
                    let cancel = UIAlertAction(title: L10n.Common.Alerts.UnfollowUser.cancel, style: .default) { _ in
                        NotificationCenter.default.post(name: .relationshipChanged, object: nil, userInfo: [
                            UserInfoKey.relationship: relationship
                        ])
                        
                        continuation.resume(returning: relationship)
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
        shouldMute: Bool,
        dependency: AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        FeedbackGenerator.shared.generate(.selectionChanged)
        
        let response = try await {
            if shouldMute {
                try await APIService.shared.mute(
                    account.id,
                    authenticationBox: dependency.authenticationBox
                )
            } else {
                try await APIService.shared.unmute(
                    account.id,
                    authenticationBox: dependency.authenticationBox
                )
            }
        }()
        
        let userInfo = [
            UserInfoKey.relationship: response,
        ]
        
        NotificationCenter.default.post(name: .relationshipChanged, object: self, userInfo: userInfo)
        
        return response
    }
    
    static func responseToUserBlockAction(
        shouldBlock: Bool,
        dependency: AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        FeedbackGenerator.shared.generate(.selectionChanged)
        
        let apiService = APIService.shared
        let authBox = dependency.authenticationBox
        
        let response = try await {
            if shouldBlock {
                return try await apiService.block(account.id, authenticationBox: authBox)
            } else {
                return try await apiService.unblock(account.id, authenticationBox: authBox)
            }
        }()
        
        let userInfo = [
            UserInfoKey.relationship: response,
        ]
        
        NotificationCenter.default.post(name: .relationshipChanged, object: self, userInfo: userInfo)
        
        return response
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
        case .status, .notificationBanner(_):
            break
            
        }
    }
    
    enum DataSourceItem: Hashable {
        case status(record: MastodonStatus)
        case hashtag(tag: Mastodon.Entity.Tag)
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
