import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import os.log

public final class StatusDataController {
    private let logger = Logger(subsystem: "StatusDataController", category: "Data")
    private static let entryNotFoundMessage = "Failed to find suitable record. Depending on the context this might result in errors (data not being updated) or can be discarded (e.g. when there are mixed data sources where an entry might or might not exist)."

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
        case .pollVote:
            updateEdited(status) // technically the data changed so refresh it to reflect the new data
        }
    }
    
    @MainActor
    private func updateEdited(_ status: MastodonStatus) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            logger.warning("\(Self.entryNotFoundMessage)")
            return
        }
        newRecords[index] = status.inheritSensitivityToggled(from: newRecords[index])
        records = newRecords
    }
    
    @MainActor
    private func updateBookmarked(_ status: MastodonStatus, _ isBookmarked: Bool) {
        var newRecords = Array(records)
        guard let index = newRecords.firstIndex(where: { $0.id == status.id }) else {
            logger.warning("\(Self.entryNotFoundMessage)")
            return
        }
        newRecords[index] = status.inheritSensitivityToggled(from: newRecords[index])
        records = newRecords
    }
    
    @MainActor
    private func updateFavorited(_ status: MastodonStatus, _ isFavorited: Bool) {
        var newRecords = Array(records)
        if let index = newRecords.firstIndex(where: { $0.id == status.id }) {
            // Replace old status entity
            let existingRecord = newRecords[index]
            let newStatus = status.inheritSensitivityToggled(from: existingRecord)
                .withOriginal(status: existingRecord)
            newRecords[index] = newStatus
        } else if let index = newRecords.firstIndex(where: { $0.reblog?.id == status.id }) {
            // Replace reblogged entity of old "parent" status
            let existingRecord = newRecords[index]
            let newStatus = status.inheritSensitivityToggled(from: existingRecord)
                .withOriginal(status: existingRecord)
            newStatus.reblog = status
            newRecords[index] = newStatus
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
            if let idx = newRecords.firstIndex(where: { $0.reblog?.id == status.reblog?.id }) {
                index = idx
            } else if let idx = newRecords.firstIndex(where: { $0.id == status.reblog?.id }) {
                index = idx
            } else {
                logger.warning("\(Self.entryNotFoundMessage)")
                return
            }
            let existingStatus = newRecords[index]
            newRecords[index] = status.withOriginal(status: existingStatus)
        case false:
            let index: Int
            if let idx = newRecords.firstIndex(where: { $0.reblog?.id == status.id }) {
                index = idx
            } else if let idx = newRecords.firstIndex(where: { $0.id == status.id }) {
                index = idx
            } else {
                logger.warning("\(Self.entryNotFoundMessage)")
                return
            }
            let existingRecord = newRecords[index]
            let newStatus = existingRecord.originalStatus ?? status.inheritSensitivityToggled(from: existingRecord)
            newRecords[index] = newStatus
        }
        
        records = newRecords
    }
    
    @MainActor
    private func updateSensitive(_ status: MastodonStatus, _ isVisible: Bool) {
        var newRecords = Array(records)
        if let index = newRecords.firstIndex(where: { $0.reblog?.id == status.id }) {
            let newStatus: MastodonStatus = .fromEntity(newRecords[index].entity)
            newStatus.reblog = status
            newRecords[index] = newStatus
        } else if let index = newRecords.firstIndex(where: { $0.id == status.id }) {
            let newStatus: MastodonStatus = .fromEntity(newRecords[index].entity)
                .inheritSensitivityToggled(from: status)
            newRecords[index] = newStatus
        } else {
            logger.warning("\(Self.entryNotFoundMessage)")
            return
        }
        records = newRecords
    }
    
}
