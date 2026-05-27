// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import Foundation

public struct LastReadMarkers: Identifiable, Codable {
    public enum MarkerPosition: Codable {
        case local(lastReadID: String)
        case fromServer(Mastodon.Entity.Marker.Position)
        
        public var lastReadID: String {
            switch self {
            case .local(let lastReadID):
                return lastReadID
            case .fromServer(let position):
                return position.lastReadID
            }
        }
    }
    
    public let userGUID: String
    public let homeTimelineLastRead: MarkerPosition?
    public let notificationsLastRead: MarkerPosition?
    public let mentionsLastRead: MarkerPosition?
    
    public var id: String {
        return userGUID
    }
    
    public init(userGUID: String, home: MarkerPosition?, notifications: MarkerPosition?, mentions: MarkerPosition?) {
        self.userGUID = userGUID
        self.homeTimelineLastRead = home
        self.notificationsLastRead = notifications
        if let notifications, let mentions {
            if mentions.lastReadID > notifications.lastReadID {
                self.mentionsLastRead = mentions
            } else {
                self.mentionsLastRead = nil
            }
        } else {
            self.mentionsLastRead = mentions
        }
    }
    
    public func lastRead(forKind kind: MastodonFeedKind) -> MarkerPosition? {
        switch kind {
        case .home:
            return homeTimelineLastRead
        case .notificationsAll:
            return notificationsLastRead
        case .notificationsMentionsOnly:
            return mentionsLastRead ?? notificationsLastRead
        case .notificationsWithAccount:
            return nil
        }
    }
    
    public func bySettingPosition(_ newPosition: MarkerPosition, forKind kind: MastodonFeedKind, enforceForwardProgress: Bool) -> LastReadMarkers {
        if let previous = lastRead(forKind: kind) {
            guard !enforceForwardProgress || LastReadMarkers.id(previous.lastReadID, isOlderThan: newPosition.lastReadID) else { return self }
        }
        switch kind {
        case .home:
            return LastReadMarkers(userGUID: userGUID, home: newPosition, notifications: notificationsLastRead, mentions: mentionsLastRead)
        case .notificationsAll:
            return LastReadMarkers(userGUID: userGUID, home: homeTimelineLastRead, notifications: newPosition, mentions: mentionsLastRead)
        case .notificationsMentionsOnly:
            return LastReadMarkers(userGUID: userGUID, home: homeTimelineLastRead, notifications: notificationsLastRead, mentions: newPosition)
        case .notificationsWithAccount:
            return self
        }
    }
}

public extension LastReadMarkers {
    static func id(_ thisId: String, isOlderThan otherId: String) -> Bool {
        if thisId.count == otherId.count {
            return thisId < otherId
        } else {
            return thisId.count < otherId.count
        }
    }
}
