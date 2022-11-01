//
//  FeedFetchedResultsController.swift
//  FeedFetchedResultsController
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

final public class FeedFetchedResultsController: NSObject {
    
    public let logger = Logger(subsystem: "FeedFetchedResultsController", category: "DB")
    
    var disposeBag = Set<AnyCancellable>()
    
    public let fetchedResultsController: NSFetchedResultsController<Feed>
    
    // input
    @Published public var predicate = Feed.predicate(kind: .none, acct: .none)
    
    // output
    private let _objectIDs = PassthroughSubject<[NSManagedObjectID], Never>()
    @Published public var records: [ManagedObjectRecord<Feed>] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = Feed.sortedFetchRequest
            // make sure initial query return empty results
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.fetchBatchSize = 15
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
        
        $predicate
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] predicate in
                guard let self = self else { return }
                self.fetchedResultsController.fetchRequest.predicate = predicate
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension FeedFetchedResultsController: NSFetchedResultsControllerDelegate {
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        self._objectIDs.send(snapshot.itemIdentifiers)
    }
}

