//
//  RemoteThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

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
            let response = try await context.apiService.status(
                statusID: statusID,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            
            let threadContext = StatusItem.Thread.Context(status: .fromEntity(response.value))
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
            let response = try await context.apiService.notification(
                notificationID: notificationID,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            
            guard let status = response.value.status else { return }
            
            let threadContext = StatusItem.Thread.Context(status: .fromEntity(status))
            self.root = .root(context: threadContext)
        }   // end Task
    }
    
}
