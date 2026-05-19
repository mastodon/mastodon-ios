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
