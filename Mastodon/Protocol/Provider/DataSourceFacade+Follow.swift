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
        
        _ = try await dependency.context.apiService.followRequest(
            userID: userID,
            query: query,
            authenticationBox: authenticationBox
        )
    }   // end func
}
