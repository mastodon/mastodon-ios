//
//  FavoriteViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-6.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit

final class FavoriteViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let activeMastodonAuthenticationBox: CurrentValueSubject<AuthenticationService.MastodonAuthenticationBox?, Never>
    let statusFetchedResultsController: StatusFetchedResultsController
    let cellFrameCache = NSCache<NSNumber, NSValue>()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    
    init(context: AppContext) {
        self.context = context
        self.activeMastodonAuthenticationBox = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value)
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalTweetPredicate: Status.notDeleted()
        )
        
        context.authenticationService.activeMastodonAuthenticationBox
            .assign(to: \.value, on: activeMastodonAuthenticationBox)
            .store(in: &disposeBag)
        
        activeMastodonAuthenticationBox
            .map { $0?.domain }
            .assign(to: \.value, on: statusFetchedResultsController.domain)
            .store(in: &disposeBag)
        
        statusFetchedResultsController.objectIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objectIDs in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var items: [Item] = []
                var snapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
                snapshot.appendSections([.main])
                
                defer {
                    // not animate when empty items fix loader first appear layout issue
                    diffableDataSource.apply(snapshot, animatingDifferences: !items.isEmpty)
                }
                
                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
                let oldSnapshot = diffableDataSource.snapshot()
                for item in oldSnapshot.itemIdentifiers {
                    guard case let .status(objectID, attribute) = item else { continue }
                    oldSnapshotAttributeDict[objectID] = attribute
                }
                
                for objectID in objectIDs {
                    let attribute = oldSnapshotAttributeDict[objectID] ?? Item.StatusAttribute()
                    items.append(.status(objectID: objectID, attribute: attribute))
                }
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Reloading, is State.Loading, is State.Idle, is State.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    case is State.NoMore:
                        break
                    // TODO: handle other states
                    default:
                        break
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
}
