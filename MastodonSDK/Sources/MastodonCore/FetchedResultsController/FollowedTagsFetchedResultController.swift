//
//  FollowedTagsFetchedResultController.swift
//  
//
//  Created by Marcus Kida on 23.11.22.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class FollowedTagsFetchedResultController: NSObject {

    var disposeBag = Set<AnyCancellable>()

    let fetchedResultsController: NSFetchedResultsController<Tag>

    // input
    @Published public var domain: String? = nil
    @Published public var user: MastodonUser? = nil

    // output
    let _objectIDs = CurrentValueSubject<[NSManagedObjectID], Never>([])
    @Published public private(set) var records: [ManagedObjectRecord<Tag>] = []
    
    public init(managedObjectContext: NSManagedObjectContext, domain: String, user: MastodonUser) {
        self.domain = domain
        self.fetchedResultsController = {
            let fetchRequest = Tag.sortedFetchRequest
            fetchRequest.predicate = Tag.predicate(domain: domain, following: true, by: user)
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
        
        // debounce output to prevent UI update issues
        _objectIDs
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .map { objectIDs in objectIDs.map { ManagedObjectRecord(objectID: $0) } }
            .assign(to: &$records)
        
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        
        Publishers.CombineLatest(
            self.$domain,
            self.$user
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] domain, user in
            guard let self = self, let domain = domain, let user = user else { return }
            self.fetchedResultsController.fetchRequest.predicate = Tag.predicate(domain: domain, following: true, by: user)
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
extension FollowedTagsFetchedResultController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let objects = fetchedResultsController.fetchedObjects ?? []
        
        let items: [NSManagedObjectID] = objects
//            .compactMap { object in
//                indexes.firstIndex(of: object.id).map { index in (index, object) }
//            }
//            .sorted { $0.0 < $1.0 }
            .map { $0.objectID }
        self._objectIDs.value = items
    }
}
