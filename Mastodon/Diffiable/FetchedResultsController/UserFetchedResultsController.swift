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

final class UserFetchedResultsController: NSObject {

    var disposeBag = Set<AnyCancellable>()

    let fetchedResultsController: NSFetchedResultsController<MastodonUser>

    // input
    let domain = CurrentValueSubject<String?, Never>(nil)
    let userIDs = CurrentValueSubject<[Mastodon.Entity.Account.ID], Never>([])

    // output
    let objectIDs = CurrentValueSubject<[NSManagedObjectID], Never>([])

    init(managedObjectContext: NSManagedObjectContext, domain: String?, additionalTweetPredicate: NSPredicate?) {
        self.domain.value = domain ?? ""
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
        super.init()

        fetchedResultsController.delegate = self

        Publishers.CombineLatest(
            self.domain.removeDuplicates().eraseToAnyPublisher(),
            self.userIDs.removeDuplicates().eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] domain, ids in
            guard let self = self else { return }
            var predicates = [MastodonUser.predicate(domain: domain ?? "", ids: ids)]
            if let additionalPredicate = additionalTweetPredicate {
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

// MARK: - NSFetchedResultsControllerDelegate
extension UserFetchedResultsController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let indexes = userIDs.value
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
