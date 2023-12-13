//
//  FeedFetchedResultsController.swift
//  FeedFetchedResultsController
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import UIKit
import Combine
import MastodonSDK
import MastodonCore

final public class FeedFetchedResultsController {

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
                switch status.entity.reblogged {
                case .some(true):
                    newRecords[i] = .fromStatus({
                        let stat = MastodonStatus.fromEntity(records[i].status!.entity)
                        stat.isSensitiveToggled = status.isSensitiveToggled
                        stat.reblog = .fromEntity(status.entity)
                        return stat
                    }(), kind: record.kind)
                case .some(false), .none:
                    newRecords[i] = .fromStatus({
                        let stat = MastodonStatus.fromEntity(status.entity)
                        stat.isSensitiveToggled = status.isSensitiveToggled
                        return stat
                    }(), kind: record.kind)
                }

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

private extension FeedFetchedResultsController {
    func load(kind: MastodonFeed.Kind, sinceId: MastodonStatus.ID?) async throws -> [MastodonFeed] {
        switch kind {
            case .home:
                await context.authenticationService.authenticationServiceProvider.fetchAccounts(apiService: context.apiService)
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
