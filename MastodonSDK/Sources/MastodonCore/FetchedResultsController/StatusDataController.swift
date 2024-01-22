import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class StatusDataController {
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
                let isRebloggedByAnyOne: Bool = records[i].reblog != nil

                let newStatus: MastodonStatus
                if isRebloggedByAnyOne {
                    // if status was previously reblogged by me: remove reblogged status
                    if records[i].entity.reblogged == true && status.entity.reblogged == false {
                        newStatus = .fromEntity(status.entity)
                    } else {
                        newStatus = .fromEntity(records[i].entity)
                    }
                    
                } else {
                    newStatus = .fromEntity(status.entity)
                }

                newStatus.isSensitiveToggled = status.isSensitiveToggled
                newStatus.reblog = isRebloggedByAnyOne ? .fromEntity(status.entity) : nil
                
                newRecords[i] = newStatus
            } else if let reblog = record.reblog, reblog.id == status.reblog?.id {
                // Handle re-reblogged state
                newRecords[i] = status
            }
        }
        records = newRecords
    }
}
