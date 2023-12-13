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
    static func responseToUserFollowAction(
        dependency: NeedsDependency & AuthContextProvider,
        user: ManagedObjectRecord<MastodonUser>
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
    
        _ = try await dependency.context.apiService.toggleFollow(
            user: user,
            authenticationBox: dependency.authContext.mastodonAuthenticationBox
        )
        dependency.context.authenticationService.fetchFollowingAndBlockedAsync()
    }

    static func responseToUserFollowAction(
        dependency: NeedsDependency & AuthContextProvider,
        user: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        let response = try await dependency.context.apiService.toggleFollow(
            user: user,
            authenticationBox: dependency.authContext.mastodonAuthenticationBox
        ).value

        dependency.context.authenticationService.fetchFollowingAndBlockedAsync()

        return response
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
        let _userID: String? = try await managedObjectContext.perform {
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
    account: Mastodon.Entity.Account
  ) async throws {
      #warning("TODO: Implement")
//    _ = try await dependency.context.apiService.toggleShowReblogs(
//      for: user,
//      authenticationBox: dependency.authContext.mastodonAuthenticationBox)
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
