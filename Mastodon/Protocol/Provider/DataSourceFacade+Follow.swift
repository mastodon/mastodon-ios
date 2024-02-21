//
//  DataSourceFacade+Follow.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import CoreDataStack
import class CoreDataStack.Notification
import MastodonCore
import MastodonSDK
import MastodonLocalization

extension DataSourceFacade {
    @MainActor
    static func responseToUserFollowAction(
        dependency: ViewControllerWithDependencies & AuthContextProvider,
        user: ManagedObjectRecord<MastodonUser>
    ) async throws {

        let authBox = dependency.authContext.mastodonAuthenticationBox
        guard let userObject = user.object(in: dependency.context.managedObjectContext) else { return }
        
        let relationship = try await dependency.context.apiService.relationship(
            records: [user],
            authenticationBox: authBox
        ).value.first
        
        let performUnfollow = {
            let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator.selectionChanged()
        
            _ = try await dependency.context.apiService.toggleFollow(
                user: user,
                authenticationBox: authBox
            )
            dependency.context.authenticationService.fetchFollowingAndBlockedAsync()
        }
        
        if relationship?.following == true {
            let alert = UIAlertController(
                title: L10n.Common.Alerts.UnfollowUser.title("@\(userObject.username)"),
                message: nil,
                preferredStyle: .alert
            )
            let cancel = UIAlertAction(title: L10n.Common.Alerts.UnfollowUser.cancel, style: .default)
            alert.addAction(cancel)
            let unfollow = UIAlertAction(title: L10n.Common.Alerts.UnfollowUser.unfollow, style: .destructive) {_ in
                Task {
                    try await performUnfollow()
                }
            }
            alert.addAction(unfollow)
            dependency.present(alert, animated: true)
        } else {
            try await performUnfollow()
        }
    }

    @MainActor
    static func responseToUserFollowAction(
        dependency: ViewControllerWithDependencies & AuthContextProvider,
        user: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        let authBox = dependency.authContext.mastodonAuthenticationBox
        let relationship = try await dependency.context.apiService.relationship(
            forAccounts: [user], authenticationBox: authBox
        ).value.first
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let performAction = {
                    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
                    selectionFeedbackGenerator.selectionChanged()
                    
                    let response = try await dependency.context.apiService.toggleFollow(
                        user: user,
                        authenticationBox: dependency.authContext.mastodonAuthenticationBox
                    ).value
                    
                    dependency.context.authenticationService.fetchFollowingAndBlockedAsync()
                    
                    continuation.resume(returning: response)
                }

                if relationship?.following == true {
                    let alert = UIAlertController(
                        title: L10n.Common.Alerts.UnfollowUser.title("@\(user.username)"),
                        message: nil,
                        preferredStyle: .alert
                    )
                    let cancel = UIAlertAction(title: L10n.Common.Alerts.UnfollowUser.cancel, style: .default)
                    alert.addAction(cancel)
                    let unfollow = UIAlertAction(title: L10n.Common.Alerts.UnfollowUser.unfollow, style: .destructive) {_ in
                        Task {
                            try await performAction()
                        }
                    }
                    alert.addAction(unfollow)
                    dependency.present(alert, animated: true)
                } else {
                    try await performAction()
                }
            }
        }
    }

}

extension DataSourceFacade {
    static func responseToUserFollowRequestAction(
        dependency: NeedsDependency & AuthContextProvider,
        notification: MastodonNotification,
        query: Mastodon.API.Account.FollowRequestQuery
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
        
        let managedObjectContext = dependency.context.managedObjectContext
        let _userID: MastodonUser.ID? = try await managedObjectContext.perform {
            return notification.account.id
        }
        
        guard let userID = _userID else {
            assertionFailure()
            throw APIService.APIError.implicit(.badRequest)
        }
        
        let state: MastodonFollowRequestState = notification.followRequestState
        
        guard state.state == .none else {
            return
        }
        
        switch query {
        case .accept:
            notification.transientFollowRequestState = .init(state: .isAccepting)
        case .reject:
            notification.transientFollowRequestState = .init(state: .isRejecting)
        }
        
        do {
            _ = try await dependency.context.apiService.followRequest(
                userID: userID,
                query: query,
                authenticationBox: dependency.authContext.mastodonAuthenticationBox
            )
        } catch {
            // reset state when failure
            notification.transientFollowRequestState = .init(state: .none)
            
            if let error = error as? Mastodon.API.Error {
                switch error.httpResponseStatus {
                case .notFound:
                    break
                default:
                    let alertController = await UIAlertController(for: error, title: nil, preferredStyle: .alert)
                    let okAction = await UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default)
                    await alertController.addAction(okAction)
                    _ = await dependency.coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
            }
            
            return
        }
        
        switch query {
        case .accept:
            notification.transientFollowRequestState = .init(state: .isAccept)
            notification.followRequestState = .init(state: .isAccept)
        case .reject:
            break
        }
    }
}

extension DataSourceFacade {
  static func responseToShowHideReblogAction(
    dependency: NeedsDependency & AuthContextProvider,
    user: ManagedObjectRecord<MastodonUser>
  ) async throws {
    _ = try await dependency.context.apiService.toggleShowReblogs(
      for: user,
      authenticationBox: dependency.authContext.mastodonAuthenticationBox)
  }
    
    static func responseToShowHideReblogAction(
      dependency: NeedsDependency & AuthContextProvider,
      user: Mastodon.Entity.Account
    ) async throws {
      _ = try await dependency.context.apiService.toggleShowReblogs(
        for: user,
        authenticationBox: dependency.authContext.mastodonAuthenticationBox)
    }
}
