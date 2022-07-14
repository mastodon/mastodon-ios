//
//  MastodonNotification.swift
//  NotificationService
//
//  Created by MainasuK Cirno on 2021-4-26.
//

import Foundation

struct MastodonPushNotification: Codable {
    
    let accessToken: String
//    var accessToken: String {
//        return String.normalize(base64String: _accessToken)
//    }

    let notificationID: Int
    let notificationType: String
    
    let preferredLocale: String?
    let icon: String?
    let title: String
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case notificationID = "notification_id"
        case notificationType = "notification_type"
        case preferredLocale = "preferred_locale"
        case icon
        case title
        case body
    }
    
    public init(
        accessToken: String,
        notificationID: Int,
        notificationType: String,
        preferredLocale: String?,
        icon: String?,
        title: String,
        body: String
    ) {
        self.accessToken = accessToken
        self.notificationID = notificationID
        self.notificationType = notificationType
        self.preferredLocale = preferredLocale
        self.icon = icon
        self.title = title
        self.body = body
    }
    
}
