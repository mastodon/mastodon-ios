//
//  SettingFetchedResultController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class SettingFetchedResultController: NSObject {

    let fetchedResultsController: NSFetchedResultsController<Setting>

    // input
    
    // output
    public let settings = CurrentValueSubject<[Setting], Never>([])
    
    override public init() {
        self.fetchedResultsController = {
            let fetchRequest = Setting.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: PersistenceManager.shared.mainActorManagedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        super.init()
        
        fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension SettingFetchedResultController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        let objects = fetchedResultsController.fetchedObjects ?? []
        self.settings.value = objects
    }
}
