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

final class SearchHistoryFetchedResultController: NSObject {

    var disposeBag = Set<AnyCancellable>()

    let fetchedResultsController: NSFetchedResultsController<SearchHistory>

    // output
    let objectIDs = CurrentValueSubject<[NSManagedObjectID], Never>([])

    init(managedObjectContext: NSManagedObjectContext) {
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

        fetchedResultsController.delegate = self
    }

}

// MARK: - NSFetchedResultsControllerDelegate
extension SearchHistoryFetchedResultController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let objects = fetchedResultsController.fetchedObjects ?? []
        self.objectIDs.value = objects.map { $0.objectID }
    }
}
