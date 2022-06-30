//
//  DataSourceFacade+Follow.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import CoreDataStack
import class CoreDataStack.Notification
import MastodonSDK
import MastodonLocalization

extension DataSourceFacade {
    static func responseToUserFollowAction(
        dependency: NeedsDependency,
        user: ManagedObjectRecord<MastodonUser>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
    
        _ = try await dependency.context.apiService.toggleFollow(
            user: user,
            authenticationBox: authenticationBox
        )
    }   // end func
}

extension DataSourceFacade {
    static func responseToUserFollowRequestAction(
        dependency: NeedsDependency,
        notification: ManagedObjectRecord<Notification>,
        query: Mastodon.API.Account.FollowReqeustQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
    
        let managedObjectContext = dependency.context.managedObjectContext
        let _userID: MastodonUser.ID? = try await managedObjectContext.perform {
            guard let notification = notification.object(in: managedObjectContext) else { return nil }
            return notification.account.id
        }
        
        guard let userID = _userID else {
            assertionFailure()
            throw APIService.APIError.implicit(.badRequest)
        }
        
        let state: MastodonFollowRequestState = try await managedObjectContext.perform {
            guard let notification = notification.object(in: managedObjectContext) else { return .init(state: .none) }
            return notification.followRequestState
        }
        
        guard state.state == .none else {
            return
        }
        
        try? await managedObjectContext.performChanges {
            guard let notification = notification.object(in: managedObjectContext) else { return }
            switch query {
            case .accept:
                notification.transientFollowRequestState = .init(state: .isAccepting)
            case .reject:
                notification.transientFollowRequestState = .init(state: .isRejecting)
            }
        }
        
        do {
            _ = try await dependency.context.apiService.followRequest(
                userID: userID,
                query: query,
                authenticationBox: authenticationBox
            )
        } catch {
            try? await managedObjectContext.performChanges {
                guard let notification = notification.object(in: managedObjectContext) else { return }
                notification.transientFollowRequestState = .init(state: .none)
            }

            if let error = error as? Mastodon.API.Error {
                switch error.httpResponseStatus {
                case .notFound:
                    let backgroundManagedObjectContext = dependency.context.backgroundManagedObjectContext
                    try await backgroundManagedObjectContext.performChanges {
                        guard let notification = notification.object(in: backgroundManagedObjectContext) else { return }
                        for feed in notification.feeds {
                            backgroundManagedObjectContext.delete(feed)
                        }
                        backgroundManagedObjectContext.delete(notification)
                    }
                default:
                    let alertController = await UIAlertController(for: error, title: nil, preferredStyle: .alert)
                    let okAction = await UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default)
                    await alertController.addAction(okAction)
                    await dependency.coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
            }
            
            return
        }
        
        try? await managedObjectContext.performChanges {
            guard let notification = notification.object(in: managedObjectContext) else { return }
            switch query {
            case .accept:
                notification.transientFollowRequestState = .init(state: .isAccept)
            case .reject:
                notification.transientFollowRequestState = .init(state: .isReject)
            }
        }
        
        let backgroundManagedObjectContext = dependency.context.backgroundManagedObjectContext
        try? await backgroundManagedObjectContext.performChanges {
            guard let notification = notification.object(in: backgroundManagedObjectContext) else { return }
            switch query {
            case .accept:
                notification.followRequestState = .init(state: .isAccept)
            case .reject:
                notification.followRequestState = .init(state: .isReject)
            }
        }
    }   // end func
}
