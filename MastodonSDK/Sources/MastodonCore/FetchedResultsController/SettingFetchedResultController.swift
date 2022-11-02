//
//  SettingFetchedResultController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class SettingFetchedResultController: NSObject {

    var disposeBag = Set<AnyCancellable>()

    let fetchedResultsController: NSFetchedResultsController<Setting>

    // input
    
    // output
    public let settings = CurrentValueSubject<[Setting], Never>([])
    
    public init(managedObjectContext: NSManagedObjectContext, additionalPredicate: NSPredicate?) {
        self.fetchedResultsController = {
            let fetchRequest = Setting.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            if let additionalPredicate = additionalPredicate {
                fetchRequest.predicate = additionalPredicate
            }
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
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
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let objects = fetchedResultsController.fetchedObjects ?? []
        self.settings.value = objects
    }
}
