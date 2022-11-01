//
//  Mastodon+Entity+Notification+Type.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/19.
//

import Foundation
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonLocalization

extension Mastodon.Entity.Notification.NotificationType {
    public var color: UIColor {
        get {
            var color: UIColor
            switch self {
            case .follow:
                color = Asset.Colors.brand.color
            case .favourite:
                color = Asset.Colors.Notification.favourite.color
            case .reblog:
                color = Asset.Colors.Notification.reblog.color
            case .mention:
                color = Asset.Colors.Notification.mention.color
            case .poll:
                color = Asset.Colors.brand.color
            case .followRequest:
                color = Asset.Colors.brand.color
            default:
                color = .clear
            }
            return color
        }
    }
    
//    public var actionText: String {
//        get {
//            var actionText: String
//            switch self {
//            case .follow:
//                actionText = L10n.Scene.Notification.Action.follow
//            case .favourite:
//                actionText = L10n.Scene.Notification.Action.favourite
//            case .reblog:
//                actionText = L10n.Scene.Notification.Action.reblog
//            case .mention:
//                actionText = L10n.Scene.Notification.Action.mention
//            case .poll:
//                actionText = L10n.Scene.Notification.Action.poll
//            case .followRequest:
//                actionText = L10n.Scene.Notification.Action.followRequest
//            default:
//                actionText = ""
//            }
//            return actionText
//        }
//    }
    
    public var actionImageName: String {
        get {
            var actionImageName: String
            switch self {
            case .follow:
                actionImageName = "person.crop.circle.badge.checkmark"
            case .favourite:
                actionImageName = "star.fill"
            case .reblog:
                actionImageName = "arrow.2.squarepath"
            case .mention:
                actionImageName = "at"
            case .poll:
                actionImageName = "list.bullet"
            case .followRequest:
                actionImageName = "person.crop.circle"
            default:
                actionImageName = ""
            }
            return actionImageName
        }
    }
}
