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

            records += try await load(kind: kind, sinceId: lastId)
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
        }
        
        return
                
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
    
    @MainActor
    private func delete(_ status: MastodonStatus) {
        records.removeAll { $0.id == status.id }
    }
    
    @MainActor
    private func updateEdited(_ status: MastodonStatus) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to find suitable record")
            return
        }
        let existingRecord = newRecords[index]
        let newStatus = status
        newStatus.isSensitiveToggled = existingRecord.status?.isSensitiveToggled == true
        newRecords[index] = .fromStatus(newStatus, kind: existingRecord.kind)
        records = newRecords
    }
    
    @MainActor
    private func updateBookmarked(_ status: MastodonStatus, _ isBookmarked: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to find suitable record")
            return
        }
        let existingRecord = newRecords[index]
        newRecords[index] = .fromStatus(status, kind: existingRecord.kind)
        records = newRecords
    }
    
    @MainActor
    private func updateFavorited(_ status: MastodonStatus, _ isFavorited: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to find suitable record")
            return
        }
        let existingRecord = newRecords[index]
        newRecords[index] = .fromStatus(status, kind: existingRecord.kind)
        records = newRecords
    }
    
    @MainActor
    private func updateReblogged(_ status: MastodonStatus, _ isReblogged: Bool) {
        var newRecords = Array(records)

        switch isReblogged {
        case true:
            guard let reblog = status.reblog else {
                assertionFailure("Reblogged entity not found")
                return
            }
            guard let index = newRecords.firstIndex(where: { $0.id == reblog.id }) else {
                assertionFailure("Failed to find suitable record")
                return
            }
            let existingRecord = newRecords[index]
            newRecords[index] = .fromStatus(status, kind: existingRecord.kind)
        case false:
            let index: Int
            
            if let idx = newRecords.firstIndex(where: { $0.status?.reblog?.id == status.id }) {
                index = idx
            } else if let idx = newRecords.firstIndex(where: { $0.status?.id == status.id }) {
                index = idx
            } else {
                assertionFailure("Failed to find suitable record")
                return
            }
            let existingRecord = newRecords[index]
            newRecords[index] = .fromStatus(status, kind: existingRecord.kind)
        }
        records = newRecords
    }
    
    @MainActor
    private func updateSensitive(_ status: MastodonStatus, _ isVisible: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to find suitable record")
            return
        }
        let existingRecord = newRecords[index]
        newRecords[index] = .fromStatus(status, kind: existingRecord.kind)
        records = newRecords
    }
}

private extension FeedDataController {
    func load(kind: MastodonFeed.Kind, sinceId: MastodonStatus.ID?) async throws -> [MastodonFeed] {
        switch kind {
        case .home:
            return try await context.apiService.homeTimeline(sinceID: sinceId, authenticationBox: authContext.mastodonAuthenticationBox)
                .value.map { .fromStatus(.fromEntity($0), kind: .home) }
        case .notificationAll:
            return try await context.apiService.notifications(maxID: nil, scope: .everything, authenticationBox: authContext.mastodonAuthenticationBox)
                .value.map { .fromNotification($0, kind: .notificationAll) }
        case .notificationMentions:
            return try await context.apiService.notifications(maxID: nil, scope: .mentions, authenticationBox: authContext.mastodonAuthenticationBox)
                .value.map { .fromNotification($0, kind: .notificationMentions) }
        }
    }
}
