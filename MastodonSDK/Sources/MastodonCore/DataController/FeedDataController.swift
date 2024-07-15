import Foundation
import UIKit
import Combine
import MastodonSDK
import os.log

final public class FeedDataController {
    private let logger = Logger(subsystem: "FeedDataController", category: "Data")
    private static let entryNotFoundMessage = "Failed to find suitable record. Depending on the context this might result in errors (data not being updated) or can be discarded (e.g. when there are mixed data sources where an entry might or might not exist)."

    @Published public var records: [MastodonFeed] = []
    
    private let context: AppContext
    private let authContext: AuthContext

    public init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
    }
    
    public func loadInitial(kind: MastodonFeed.Kind) {
        Task {
            records = try await load(kind: kind, maxID: nil)
        }
    }
    
    public func loadNext(kind: MastodonFeed.Kind) {
        Task {
            guard let lastId = records.last?.status?.id else {
                return loadInitial(kind: kind)
            }

            records += try await load(kind: kind, maxID: lastId)
        }
    }
    
    @MainActor
    public func update(status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        switch intent {
        case .delete:
            delete(status)
        case .edit:
            updateEdited(status)
        case let .bookmark(isBookmarked):
            updateBookmarked(status, isBookmarked)
        case let .favorite(isFavorited):
            updateFavorited(status, isFavorited)
        case let .reblog(isReblogged):
            updateReblogged(status, isReblogged)
        case let .toggleSensitive(isVisible):
            updateSensitive(status, isVisible)
        case .pollVote:
            updateEdited(status) // technically the data changed so refresh it to reflect the new data
        }
    }
    
    @MainActor
    private func delete(_ status: MastodonStatus) {
        records.removeAll { $0.id == status.id }
    }
    
    @MainActor
    private func updateEdited(_ status: MastodonStatus) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            logger.warning("\(Self.entryNotFoundMessage)")
            return
        }
        let existingRecord = newRecords[index]
        let newStatus = status.inheritSensitivityToggled(from: existingRecord.status)
        newRecords[index] = .fromStatus(newStatus, kind: existingRecord.kind)
        records = newRecords
    }
    
    @MainActor
    private func updateBookmarked(_ status: MastodonStatus, _ isBookmarked: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            logger.warning("\(Self.entryNotFoundMessage)")
            return
        }
        let existingRecord = newRecords[index]
        let newStatus = status.inheritSensitivityToggled(from: existingRecord.status)
        newRecords[index] = .fromStatus(newStatus, kind: existingRecord.kind)
        records = newRecords
    }
    
    @MainActor
    private func updateFavorited(_ status: MastodonStatus, _ isFavorited: Bool) {
        var newRecords = Array(records)
        if let index = newRecords.firstIndex(where: { $0.id == status.id }) {
            // Replace old status entity
            let existingRecord = newRecords[index]
            let newStatus = status.inheritSensitivityToggled(from: existingRecord.status).withOriginal(status: existingRecord.status?.originalStatus)
            newRecords[index] = .fromStatus(newStatus, kind: existingRecord.kind)
        } else if let index = newRecords.firstIndex(where: { $0.status?.reblog?.id == status.id }) {
            // Replace reblogged entity of old "parent" status
            let newStatus: MastodonStatus
            if let existingEntity = newRecords[index].status?.entity {
                newStatus = .fromEntity(existingEntity)
                newStatus.originalStatus = newRecords[index].status?.originalStatus
                newStatus.reblog = status
            } else {
                newStatus = status
            }
            newRecords[index] = .fromStatus(newStatus, kind: newRecords[index].kind)
        } else {
            logger.warning("\(Self.entryNotFoundMessage)")
        }
        records = newRecords
    }
    
    @MainActor
    private func updateReblogged(_ status: MastodonStatus, _ isReblogged: Bool) {
        var newRecords = Array(records)

        switch isReblogged {
        case true:
            let index: Int
            if let idx = newRecords.firstIndex(where: { $0.status?.reblog?.id == status.reblog?.id }) {
                index = idx
            } else if let idx = newRecords.firstIndex(where: { $0.id == status.reblog?.id }) {
                index = idx
            } else {
                logger.warning("\(Self.entryNotFoundMessage)")
                return
            }
            let existingRecord = newRecords[index]
            newRecords[index] = .fromStatus(status.withOriginal(status: existingRecord.status), kind: existingRecord.kind)
        case false:
            let index: Int
            if let idx = newRecords.firstIndex(where: { $0.status?.reblog?.id == status.id }) {
                index = idx
            } else if let idx = newRecords.firstIndex(where: { $0.status?.id == status.id }) {
                index = idx
            } else {
                logger.warning("\(Self.entryNotFoundMessage)")
                return
            }
            let existingRecord = newRecords[index]
            let newStatus = existingRecord.status?.originalStatus ?? status.inheritSensitivityToggled(from: existingRecord.status)
            newRecords[index] = .fromStatus(newStatus, kind: existingRecord.kind)
        }
        records = newRecords
    }
    
    @MainActor
    private func updateSensitive(_ status: MastodonStatus, _ isVisible: Bool) {
        var newRecords = Array(records)
        if let index = newRecords.firstIndex(where: { $0.status?.reblog?.id == status.id }), let existingEntity = newRecords[index].status?.entity {
            let existingRecord = newRecords[index]
            let newStatus: MastodonStatus = .fromEntity(existingEntity)
            newStatus.reblog = status
            newRecords[index] = .fromStatus(newStatus, kind: existingRecord.kind)
        } else if let index = newRecords.firstIndex(where: { $0.id == status.id }), let existingEntity = newRecords[index].status?.entity {
            let existingRecord = newRecords[index]
            let newStatus: MastodonStatus = .fromEntity(existingEntity)
                .inheritSensitivityToggled(from: status)
            newRecords[index] = .fromStatus(newStatus, kind: existingRecord.kind)
        } else {
            logger.warning("\(Self.entryNotFoundMessage)")
            return
        }
        records = newRecords
    }
}

private extension FeedDataController {
  func load(kind: MastodonFeed.Kind, maxID: MastodonStatus.ID?) async throws -> [MastodonFeed] {
        switch kind {
        case .home(let timeline):
            await context.authenticationService.authenticationServiceProvider.fetchAccounts(apiService: context.apiService)

            let response: Mastodon.Response.Content<[Mastodon.Entity.Status]>

            switch timeline {
            case .home:
                response = try await context.apiService.homeTimeline(
                    maxID: maxID,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            case .public:
                response = try await context.apiService.publicTimeline(
                    query: .init(local: true, maxID: maxID),
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            case let .list(id):
                response = try await context.apiService.listTimeline(
                    id: id,
                    query: .init(maxID: maxID),
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            case let .hashtag(tag):
                response = try await context.apiService.hashtagTimeline(
                    hashtag: tag,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            }

            return response.value.map { .fromStatus(.fromEntity($0), kind: .home) }
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

