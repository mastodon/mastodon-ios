//
//  UserTimelineViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import AlamofireImage

class UserTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let domain: CurrentValueSubject<String?, Never>
    let userID: CurrentValueSubject<String?, Never>
    let queryFilter: CurrentValueSubject<QueryFilter, Never>
    let statusFetchedResultsController: StatusFetchedResultsController

    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.LoadingMore(viewModel: self),
            State.NotAuthorized(viewModel: self),
            State.Blocked(viewModel: self),
            State.Suspended(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()

    init(context: AppContext, domain: String?, userID: String?, queryFilter: QueryFilter) {
        self.context = context
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: domain,
            additionalTweetPredicate: Status.notDeleted()
        )
        self.domain = CurrentValueSubject(domain)
        self.userID = CurrentValueSubject(userID)
        self.queryFilter = CurrentValueSubject(queryFilter)
        super.init()

        self.domain
            .assign(to: \.value, on: statusFetchedResultsController.domain)
            .store(in: &disposeBag)
        
        
        statusFetchedResultsController.objectIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objectIDs in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                // var isPermissionDenied = false
                
                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
                let oldSnapshot = diffableDataSource.snapshot()
                for item in oldSnapshot.itemIdentifiers {
                    guard case let .status(objectID, attribute) = item else { continue }
                    oldSnapshotAttributeDict[objectID] = attribute
                }
                
                var snapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
                snapshot.appendSections([.main])

                var items: [Item] = []
                for objectID in objectIDs {
                    let attribute = oldSnapshotAttributeDict[objectID] ?? Item.StatusAttribute()
                    items.append(.status(objectID: objectID, attribute: attribute))
                }
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Reloading, is State.LoadingMore, is State.Idle, is State.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    // TODO: handle other states
                    default:
                        break
                    }
                }

                // not animate when empty items fix loader first appear layout issue
                diffableDataSource.apply(snapshot, animatingDifferences: !items.isEmpty)
            }
            .store(in: &disposeBag)
    }

    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension UserTimelineViewModel {
    struct QueryFilter {
        let excludeReplies: Bool?
        let excludeReblogs: Bool?
        let onlyMedia: Bool?
        
        init(
            excludeReplies: Bool? = nil,
            excludeReblogs: Bool? = nil,
            onlyMedia: Bool? = nil
        ) {
            self.excludeReplies = excludeReplies
            self.excludeReblogs = excludeReblogs
            self.onlyMedia = onlyMedia
        }
    }

}
