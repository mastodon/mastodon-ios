//
//  SearchHistoryFetchedResultController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class SearchHistoryFetchedResultController: NSObject {

    var disposeBag = Set<AnyCancellable>()

    public let fetchedResultsController: NSFetchedResultsController<SearchHistory>
    public let domain = CurrentValueSubject<String?, Never>(nil)
    public let userID = CurrentValueSubject<Mastodon.Entity.Status.ID?, Never>(nil)

    // output
    let _objectIDs = CurrentValueSubject<[NSManagedObjectID], Never>([])
    @Published public private(set) var records: [ManagedObjectRecord<SearchHistory>] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = SearchHistory.sortedFetchRequest
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

        Publishers.CombineLatest(
            self.domain,
            self.userID
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] domain, userID in
            guard let self = self else { return }
            let predicates = [SearchHistory.predicate(domain: domain ?? "", userID: userID ?? "")]
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

// MARK: - NSFetchedResultsControllerDelegate
extension SearchHistoryFetchedResultController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let objects = fetchedResultsController.fetchedObjects ?? []
        self._objectIDs.value = objects.map { $0.objectID }
    }
}
