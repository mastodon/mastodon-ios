//
//  SearchResultViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import GameplayKit

final class SearchResultViewModel {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let searchScope: SearchDetailViewModel.SearchScope
    let searchText = CurrentValueSubject<String, Never>("")
    let statusFetchedResultsController: StatusFetchedResultsController
    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    var navigationBarFrame = CurrentValueSubject<CGRect, Never>(.zero)

    // output
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    let items = CurrentValueSubject<[SearchResultItem], Never>([])
    var diffableDataSource: UITableViewDiffableDataSource<SearchResultSection, SearchResultItem>!
    let didDataSourceUpdate = PassthroughSubject<Void, Never>()

    init(context: AppContext, searchScope: SearchDetailViewModel.SearchScope) {
        self.context = context
        self.searchScope = searchScope
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalTweetPredicate: nil
        )

        context.authenticationService.activeMastodonAuthenticationBox
            .map { $0?.domain }
            .assign(to: \.value, on: statusFetchedResultsController.domain)
            .store(in: &disposeBag)

        Publishers.CombineLatest(
            items,
            statusFetchedResultsController.objectIDs.removeDuplicates()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] items, statusObjectIDs in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }

            var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
            snapshot.appendSections([.main])

            // append account & hashtag items

            var items = items
            if self.searchScope == .all {
                // all search scope not paging. it's safe sort on whole dataset
                items.sort(by: { ($0.sortKey ?? "") < ($1.sortKey ?? "")})
            }
            snapshot.appendItems(items, toSection: .main)

            var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
            let oldSnapshot = diffableDataSource.snapshot()
            for item in oldSnapshot.itemIdentifiers {
                guard case let .status(objectID, attribute) = item else { continue }
                oldSnapshotAttributeDict[objectID] = attribute
            }

            // append statuses
            var statusItems: [SearchResultItem] = []
            for objectID in statusObjectIDs {
                let attribute = oldSnapshotAttributeDict[objectID] ?? Item.StatusAttribute()
                statusItems.append(.status(statusObjectID: objectID, attribute: attribute))
            }
            snapshot.appendItems(statusItems, toSection: .main)

            if let currentState = self.stateMachine.currentState {
                switch currentState {
                case is State.Loading, is State.Fail, is State.Fail:
                    snapshot.appendItems([.bottomLoader], toSection: .main)
                case is State.NoMore:
                    break
                default:
                    break
                }
            }

            diffableDataSource.defaultRowAnimation = .fade
            diffableDataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                guard let self = self else { return }
                self.didDataSourceUpdate.send()
            }

        }
        .store(in: &disposeBag)
    }

}

extension SearchResultViewModel {
    func setupDiffableDataSource(
        tableView: UITableView,
        dependency: NeedsDependency,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) {
        diffableDataSource = SearchResultSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            statusTableViewCellDelegate: statusTableViewCellDelegate
        )

        var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(self.items.value, toSection: .main)    // with initial items
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
}
