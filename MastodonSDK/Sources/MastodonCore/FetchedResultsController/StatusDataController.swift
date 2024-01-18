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
    public func update(status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        
        switch intent {
        case .delete:
            deleteRecord(status)
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
      
        #warning("Remove this code")
//        if case MastodonStatus.UpdateIntent.delete = intent {
//            return deleteRecord(status)
//        }
//        
//        var newRecords = Array(records)
//        for (i, record) in newRecords.enumerated() {
//            if record.id == status.id {
//                newRecords[i] = status
//            } else if let reblog = status.reblog, reblog.id == record.id {
//                newRecords[i] = status
//            } else if let reblog = record.reblog, reblog.id == status.id {
//                // Handle reblogged state
//                let isRebloggedByAnyOne: Bool = records[i].reblog != nil
//
//                let newStatus: MastodonStatus
//                if isRebloggedByAnyOne {
//                    // if status was previously reblogged by me: remove reblogged status
//                    if records[i].entity.reblogged == true && status.entity.reblogged == false {
//                        newStatus = .fromEntity(status.entity)
//                    } else {
//                        newStatus = .fromEntity(records[i].entity)
//                    }
//                    
//                } else {
//                    newStatus = .fromEntity(status.entity)
//                }
//
//                newStatus.isSensitiveToggled = status.isSensitiveToggled
//                newStatus.reblog = isRebloggedByAnyOne ? .fromEntity(status.entity) : nil
//                
//                newRecords[i] = newStatus
//            } else if let reblog = record.reblog, reblog.id == status.reblog?.id {
//                // Handle re-reblogged state
//                newRecords[i] = status
//            }
//        }
//        records = newRecords
    }
    
    @MainActor
    private func updateEdited(_ status: MastodonStatus) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to update record")
            return
        }
        newRecords[index] = status
        records = newRecords
    }
    
    @MainActor
    private func updateBookmarked(_ status: MastodonStatus, _ isBookmarked: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to update record")
            return
        }
        newRecords[index] = status
        records = newRecords
    }
    
    @MainActor
    private func updateFavorited(_ status: MastodonStatus, _ isFavorited: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to update record")
            return
        }
        newRecords[index] = status
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
                assertionFailure("Failed to update record")
                return
            }
            newRecords[index] = status
            
        case false:
            guard let index = newRecords.firstIndex(where: { $0.reblog?.id == status.id }) else {
                assertionFailure("Failed to update record")
                return
            }
            let existingRecord = newRecords[index]
            newRecords[index] = status
        }
        
        records = newRecords
    }
    
    @MainActor
    private func updateSensitive(_ status: MastodonStatus, _ isVisible: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            assertionFailure("Failed to update record")
            return
        }
        newRecords[index] = status
        records = newRecords
    }
    
}
