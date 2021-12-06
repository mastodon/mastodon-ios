//
//  HandleTapAction.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-28.
//

import Foundation

@objc class HandleTapAction: NSObject {
    @objc static let statusBarTappedNotification = Notification(name: .statusBarTapped)
}

extension Notification.Name {
    static let statusBarTapped = Notification.Name(rawValue: "org.joinmastodon.app.statusBarTapped")
}
