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
    public func update(status: MastodonStatus) {
        var newRecords = Array(records)
        for (i, record) in newRecords.enumerated() {
            if record.id == status.id {
                newRecords[i] = status
            } else if let reblog = record.reblog, reblog.id == status.id {
                newRecords[i].reblog = status
            }
        }
        records = newRecords
    }
}
