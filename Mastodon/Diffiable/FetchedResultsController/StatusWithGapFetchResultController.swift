//
//  StatusWithGapFetchResultController.swift
//  Mastodon
//
//  Created by BradGao on 2021/4/7.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

class StatusWithGapFetchResultController: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    let fetchedResultsController: NSFetchedResultsController<Status>

    // input
    let domain = CurrentValueSubject<String?, Never>(nil)
    let statusIDs = CurrentValueSubject<[Mastodon.Entity.Status.ID], Never>([])
    
    var needLoadMiddleIndex: Int? = nil
    
    // output
    let objectIDs = CurrentValueSubject<[NSManagedObjectID], Never>([])
    
    init(managedObjectContext: NSManagedObjectContext, domain: String?, additionalTweetPredicate: NSPredicate) {
        self.domain.value = domain ?? ""
        self.fetchedResultsController = {
            let fetchRequest = Status.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
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
        
        Publishers.CombineLatest(
            self.domain.removeDuplicates().eraseToAnyPublisher(),
            self.statusIDs.removeDuplicates().eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] domain, ids in
            guard let self = self else { return }
            self.fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                Status.predicate(domain: domain ?? "", ids: ids),
                additionalTweetPredicate
            ])
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        .store(in: &disposeBag)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension StatusWithGapFetchResultController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let indexes = statusIDs.value
        let objects = fetchedResultsController.fetchedObjects ?? []
        
        let items: [NSManagedObjectID] = objects
            .compactMap { object in
                indexes.firstIndex(of: object.id).map { index in (index, object) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }
        self.objectIDs.value = items
    }
}
