//
//  RemoteThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import UIKit
import CoreDataStack
import MastodonCore
import MastodonSDK

final class RemoteThreadViewModel: ThreadViewModel {
        
    init(
        context: AppContext,
        authContext: AuthContext,
        statusID: Mastodon.Entity.Status.ID
    ) {
        super.init(
            context: context,
            authContext: authContext,
            optionalRoot: nil
        )
        
        Task { @MainActor in
            let domain = authContext.mastodonAuthenticationBox.domain
            let response = try await context.apiService.status(
                statusID: statusID,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            
            let managedObjectContext = context.managedObjectContext
            let request = Status.sortedFetchRequest
            request.fetchLimit = 1
            request.predicate = Status.predicate(domain: domain, id: response.value.id)
            guard let status = managedObjectContext.safeFetch(request).first else {
                assertionFailure()
                return
            }
            let threadContext = StatusItem.Thread.Context(status: .init(objectID: status.objectID))
            self.root = .root(context: threadContext)
            
        }   // end Task
    }
    
    init(
        context: AppContext,
        authContext: AuthContext,
        notificationID: Mastodon.Entity.Notification.ID
    ) {
        super.init(
            context: context,
            authContext: authContext,
            optionalRoot: nil
        )
        
        Task { @MainActor in
            let domain = authContext.mastodonAuthenticationBox.domain
            let response = try await context.apiService.notification(
                notificationID: notificationID,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            
            guard let statusID = response.value.status?.id else { return }
            
            let managedObjectContext = context.managedObjectContext
            let request = Status.sortedFetchRequest
            request.fetchLimit = 1
            request.predicate = Status.predicate(domain: domain, id: statusID)
            guard let status = managedObjectContext.safeFetch(request).first else {
                assertionFailure()
                return
            }
            let threadContext = StatusItem.Thread.Context(status: .init(objectID: status.objectID))
            self.root = .root(context: threadContext)
        }   // end Task
    }
    
}
