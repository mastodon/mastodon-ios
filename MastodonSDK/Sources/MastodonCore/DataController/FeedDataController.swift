import Foundation
import UIKit
import Combine
import MastodonSDK

final public class FeedDataController {

    @Published public var records: [MastodonFeed] = []
    
    private let context: AppContext
    private let authContext: AuthContext

    public init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
    }
    
    public func loadInitial(kind: MastodonFeed.Kind) {
        Task {
            records = try await load(kind: kind, sinceId: nil)
        }
    }
    
    public func loadNext(kind: MastodonFeed.Kind) {
        Task {
            guard let lastId = records.last?.status?.id else {
                return loadInitial(kind: kind)
            }
            
            records = try await load(kind: kind, sinceId: lastId)
        }
    }
    
    public func update(status: MastodonStatus) {
        var newRecords = Array(records)
        for (i, record) in newRecords.enumerated() {
            if record.status?.id == status.id {
                newRecords[i] = .fromStatus(status, kind: record.kind)
            } else if let reblog = status.reblog, reblog.id == record.status?.id {
                newRecords[i] = .fromStatus(status, kind: record.kind)
            } else if let reblog = record.status?.reblog, reblog.id == status.id {
                // Handle reblogged state
                let isRebloggedByAnyOne: Bool = records[i].status!.reblog != nil

                let newStatus: MastodonStatus
                if isRebloggedByAnyOne {
                    // if status was previously reblogged by me: remove reblogged status
                    if records[i].status!.entity.reblogged == true && status.entity.reblogged == false {
                        newStatus = .fromEntity(status.entity)
                    } else {
                        newStatus = .fromEntity(records[i].status!.entity)
                    }
                    
                } else {
                    newStatus = .fromEntity(status.entity)
                }

                newStatus.isSensitiveToggled = status.isSensitiveToggled
                newStatus.reblog = isRebloggedByAnyOne ? .fromEntity(status.entity) : nil
                
                newRecords[i] = .fromStatus(newStatus, kind: record.kind)
   
            } else if let reblog = record.status?.reblog, reblog.id == status.reblog?.id {
                // Handle re-reblogged state
                newRecords[i] = .fromStatus(status, kind: record.kind)
            }
        }
        records = newRecords
    }
    
    public func delete(status: MastodonStatus) {
        self.records.removeAll { $0.id == status.id }
    }
}

private extension FeedDataController {
    func load(kind: MastodonFeed.Kind, sinceId: MastodonStatus.ID?) async throws -> [MastodonFeed] {
        switch kind {
            case .home:
                await context.authenticationService.authenticationServiceProvider.fetchAccounts(apiService: context.apiService)
                return try await context.apiService.homeTimeline(sinceID: sinceId, authenticationBox: authContext.mastodonAuthenticationBox)
                    .value.map { .fromStatus(.fromEntity($0), kind: .home) }
            case .notificationAll:
                return try await getFeeds(with: .everything)
            case .notificationMentions:
                return try await getFeeds(with: .mentions)
        }
    }

    private func getFeeds(with scope: APIService.MastodonNotificationScope) async throws -> [MastodonFeed] {

        let notifications = try await context.apiService.notifications(maxID: nil, scope: scope, authenticationBox: authContext.mastodonAuthenticationBox).value

        let accounts = notifications.map { $0.account }
        let relationships = try await context.apiService.relationship(forAccounts: accounts, authenticationBox: authContext.mastodonAuthenticationBox).value

        let notificationsWithRelationship: [(notification: Mastodon.Entity.Notification, relationship: Mastodon.Entity.Relationship?)] = notifications.compactMap { notification in
            guard let relationship = relationships.first(where: {$0.id == notification.account.id }) else { return (notification: notification, relationship: nil)}

            return (notification: notification, relationship: relationship)
        }

        let feeds = notificationsWithRelationship.compactMap({ (notification: Mastodon.Entity.Notification, relationship: Mastodon.Entity.Relationship?) in
            MastodonFeed.fromNotification(notification, relationship: relationship, kind: .notificationAll)
        })

        return feeds
    }

}

