//
//  UserFetchedResultsController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-7.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class UserFetchedResultsController: NSObject {

    var disposeBag = Set<AnyCancellable>()

    let fetchedResultsController: NSFetchedResultsController<MastodonUser>

    // input
    @Published public var domain: String? = nil
    @Published public var userIDs: [Mastodon.Entity.Account.ID] = []
    @Published public var additionalPredicate: NSPredicate?

    // output
    let _objectIDs = CurrentValueSubject<[NSManagedObjectID], Never>([])
    @Published public private(set) var records: [ManagedObjectRecord<MastodonUser>] = []

    public init(
        managedObjectContext: NSManagedObjectContext,
        domain: String?,
        additionalPredicate: NSPredicate?
    ) {
        self.domain = domain ?? ""
        self.fetchedResultsController = {
            let fetchRequest = MastodonUser.sortedFetchRequest
            fetchRequest.predicate = MastodonUser.predicate(domain: domain ?? "", ids: [])
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
        self.additionalPredicate = additionalPredicate
        super.init()
        
        // debounce output to prevent UI update issues
        _objectIDs
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .map { objectIDs in objectIDs.map { ManagedObjectRecord(objectID: $0) } }
            .assign(to: &$records)

        fetchedResultsController.delegate = self

        Publishers.CombineLatest3(
            self.$domain.removeDuplicates(),
            self.$userIDs.removeDuplicates(),
            self.$additionalPredicate.removeDuplicates()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] domain, ids, additionalPredicate in
            guard let self = self else { return }
            var predicates = [MastodonUser.predicate(domain: domain ?? "", ids: ids)]
            if let additionalPredicate = additionalPredicate {
                predicates.append(additionalPredicate)
            }
            self.fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        .store(in: &disposeBag)
    }

}

extension UserFetchedResultsController {
    
    public func append(userIDs: [Mastodon.Entity.Account.ID]) {
        var result = self.userIDs
        for userID in userIDs where !result.contains(userID) {
            result.append(userID)
        }
        self.userIDs = result
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension UserFetchedResultsController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let indexes = userIDs
        let objects = fetchedResultsController.fetchedObjects ?? []

        let items: [NSManagedObjectID] = objects
            .compactMap { object in
                indexes.firstIndex(of: object.id).map { index in (index, object) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }
        self._objectIDs.value = items
    }
}
