//
//  RemoteThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import UIKit
import CoreDataStack
import MastodonSDK

final class RemoteThreadViewModel: ThreadViewModel {
        
    init(
        context: AppContext,
        statusID: Mastodon.Entity.Status.ID
    ) {
        super.init(
            context: context,
            optionalRoot: nil
        )
        
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        
        Task { @MainActor in
            let domain = authenticationBox.domain
            let response = try await context.apiService.status(
                statusID: statusID,
                authenticationBox: authenticationBox
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
        notificationID: Mastodon.Entity.Notification.ID
    ) {
        super.init(
            context: context,
            optionalRoot: nil
        )
        
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        
        Task { @MainActor in
            let domain = authenticationBox.domain
            let response = try await context.apiService.notification(
                notificationID: notificationID,
                authenticationBox: authenticationBox
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
