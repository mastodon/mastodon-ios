//
//  StatusFetchedResultsController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class StatusFetchedResultsController {
    @MainActor
    @Published 
    public private(set) var records: [MastodonStatus] = []
    
    @MainActor
    public init(records: [MastodonStatus] = []) {
        self.records = records
    }
    
    @MainActor
    public func reset() {
        records = []
    }
    
    @MainActor
    public func setRecords(_ records: [MastodonStatus]) {
        self.records = records
    }
    
    @MainActor
    public func appendRecords(_ records: [MastodonStatus]) {
        self.records += records
    }
    
    @MainActor
    public func deleteRecord(_ record: MastodonStatus) {
        self.records = self.records.filter { $0.id != record.id }
    }
    
    @MainActor
    public func update(status: MastodonStatus) {
        var newRecords = Array(records)
        for (i, record) in newRecords.enumerated() {
            if record.id == status.id {
                newRecords[i] = status
            } else if let reblog = status.reblog, reblog.id == record.id {
                newRecords[i] = status
            } else if let reblog = record.reblog, reblog.id == status.id {
                // Handle reblogged state
                switch status.entity.reblogged {
                case .some(true):
                    newRecords[i] = {
                        let stat = MastodonStatus.fromEntity(records[i].entity)
                        stat.isSensitiveToggled = status.isSensitiveToggled
                        stat.reblog = .fromEntity(status.entity)
                        return stat
                    }()
                case .some(false), .none:
                    newRecords[i] = {
                        let stat = MastodonStatus.fromEntity(status.entity)
                        stat.isSensitiveToggled = status.isSensitiveToggled
                        return stat
                    }()
                }

            } else if let reblog = record.reblog, reblog.id == status.reblog?.id {
                // Handle re-reblogged state
                newRecords[i] = status
            }
        }
        records = newRecords
    }
}
