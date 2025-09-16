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
    }
    
}
