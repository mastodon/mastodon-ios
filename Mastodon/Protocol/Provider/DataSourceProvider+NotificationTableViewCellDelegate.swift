//
//  DataSourceProvider+NotificationTableViewCellDelegate.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-26.
//

import UIKit
import MetaTextKit
import CoreDataStack
import MastodonCore
import MastodonUI
import MastodonSDK


private struct NotificationMediaTransitionContext {
    let status: MastodonStatus
    let needsToggleMediaSensitive: Bool
}

