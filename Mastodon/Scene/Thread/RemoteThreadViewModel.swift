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

public enum RemoteThreadType {
    case status(Mastodon.Entity.Status.ID)
    case notification(Mastodon.Entity.Notification.ID)
}

final class RemoteThreadViewModel: ThreadViewModel {
    
    let entityType: RemoteThreadType
        
    init(
        authenticationBox: MastodonAuthenticationBox,
        statusID: Mastodon.Entity.Status.ID
    ) {
        self.entityType = .status(statusID)
        super.init(
            authenticationBox: authenticationBox,
            optionalRoot: nil
        )
        
        guard !UserDefaults.standard.testNewHomeTimeline else { return }  // the new code will do the fetching, the below is unnecessary
        
        Task { @MainActor in
            let response = try await APIService.shared.status(
                statusID: statusID,
                authenticationBox: authenticationBox
            )
            
            let threadContext = MastodonItemIdentifier.Thread.Context(status: .fromEntity(response.value))
            self.root = .root(context: threadContext)
            
        }   // end Task
    }
    
    init(
        authenticationBox: MastodonAuthenticationBox,
        notificationID: Mastodon.Entity.Notification.ID
    ) {
        self.entityType = .notification(notificationID)
        super.init(
            authenticationBox: authenticationBox,
            optionalRoot: nil
        )
        
        guard !UserDefaults.standard.testNewHomeTimeline else { return }  // the new code will do the fetching, the below is unnecessary
        
        Task { @MainActor in
            let response = try await APIService.shared.notification(
                notificationID: notificationID,
                authenticationBox: authenticationBox
            )
            
            guard let status = response.value.status else { return }
            
            let threadContext = MastodonItemIdentifier.Thread.Context(status: .fromEntity(status))
            self.root = .root(context: threadContext)
        }   // end Task
    }
    
}
