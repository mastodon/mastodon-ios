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
import CommonOSLog
import MastodonSDK
import MastodonCore

final class SearchResultViewModel {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let searchScope: SearchDetailViewModel.SearchScope
    let searchText = CurrentValueSubject<String, Never>("")
    @Published var hashtags: [Mastodon.Entity.Tag] = []
    let userFetchedResultsController: UserFetchedResultsController
    let statusFetchedResultsController: StatusFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    var navigationBarFrame = CurrentValueSubject<CGRect, Never>(.zero)

    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchResultSection, SearchResultItem>!
    @Published var items: [SearchResultItem] = []
    
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
    let didDataSourceUpdate = PassthroughSubject<Void, Never>()

    init(context: AppContext, authContext: AuthContext, searchScope: SearchDetailViewModel.SearchScope) {
        self.context = context
        self.authContext = authContext
        self.searchScope = searchScope
        self.userFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: authContext.mastodonAuthenticationBox.domain,
            additionalPredicate: nil
        )
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: authContext.mastodonAuthenticationBox.domain,
            additionalTweetPredicate: nil
        )

//        Publishers.CombineLatest(
//            items,
//            statusFetchedResultsController.objectIDs.removeDuplicates()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] items, statusObjectIDs in
//            guard let self = self else { return }
//            guard let diffableDataSource = self.diffableDataSource else { return }
//
//            var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
//            snapshot.appendSections([.main])
//
//            // append account & hashtag items
//
//            var items = items
//            if self.searchScope == .all {
//                // all search scope not paging. it's safe sort on whole dataset
//                items.sort(by: { ($0.sortKey ?? "") < ($1.sortKey ?? "")})
//            }
//            snapshot.appendItems(items, toSection: .main)
//
//            var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
//            let oldSnapshot = diffableDataSource.snapshot()
//            for item in oldSnapshot.itemIdentifiers {
//                guard case let .status(objectID, attribute) = item else { continue }
//                oldSnapshotAttributeDict[objectID] = attribute
//            }
//
//            // append statuses
//            var statusItems: [SearchResultItem] = []
//            for objectID in statusObjectIDs {
//                let attribute = oldSnapshotAttributeDict[objectID] ?? Item.StatusAttribute()
//                statusItems.append(.status(statusObjectID: objectID, attribute: attribute))
//            }
//            snapshot.appendItems(statusItems, toSection: .main)
//
//            if let currentState = self.stateMachine.currentState {
//                switch currentState {
//                case is State.Loading, is State.Fail, is State.Idle:
//                    let attribute = SearchResultItem.BottomLoaderAttribute(isEmptyResult: false)
//                    snapshot.appendItems([.bottomLoader(attribute: attribute)], toSection: .main)
//                case is State.Fail:
//                    break
//                case is State.NoMore:
//                    if snapshot.itemIdentifiers.isEmpty {
//                        let attribute = SearchResultItem.BottomLoaderAttribute(isEmptyResult: true)
//                        snapshot.appendItems([.bottomLoader(attribute: attribute)], toSection: .main)
//                    }
//                default:
//                    break
//                }
//            }
//
//            diffableDataSource.defaultRowAnimation = .fade
//            diffableDataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
//                guard let self = self else { return }
//                self.didDataSourceUpdate.send()
//            }
//
//        }
//        .store(in: &disposeBag)
    }

}

extension SearchResultViewModel {
    func persistSearchHistory(for item: SearchResultItem) {
        fatalError()
//        guard let box = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
//        let property = SearchHistory.Property(domain: box.domain, userID: box.userID)
//        let domain = box.domain
//
//        switch item {
//        case .account(let entity):
//            let managedObjectContext = context.backgroundManagedObjectContext
//            managedObjectContext.performChanges {
//                let (user, _) = APIService.CoreData.createOrMergeMastodonUser(
//                    into: managedObjectContext,
//                    for: nil,
//                    in: domain,
//                    entity: entity,
//                    userCache: nil,
//                    networkDate: Date(),
//                    log: OSLog.api
//                )
//                if let searchHistory = user.findSearchHistory(domain: box.domain, userID: box.userID) {
//                    searchHistory.update(updatedAt: Date())
//                } else {
//                    SearchHistory.insert(into: managedObjectContext, property: property, account: user)
//                }
//            }
//            .sink { result in
//                switch result {
//                case .failure(let error):
//                    assertionFailure(error.localizedDescription)
//                case .success:
//                    break
//                }
//            }
//            .store(in: &context.disposeBag)
//
//        case .hashtag(let entity):
//            let managedObjectContext = context.backgroundManagedObjectContext
//            var tag: Tag?
//            managedObjectContext.performChanges {
//                let (hashtag, _) = APIService.CoreData.createOrMergeTag(
//                    into: managedObjectContext,
//                    entity: entity
//                )
//                tag = hashtag
//                if let searchHistory = hashtag.findSearchHistory(domain: box.domain, userID: box.userID) {
//                    searchHistory.update(updatedAt: Date())
//                } else {
//                    _ = SearchHistory.insert(into: managedObjectContext, property: property, hashtag: hashtag)
//                }
//            }
//            .sink { result in
//                switch result {
//                case .failure(let error):
//                    assertionFailure(error.localizedDescription)
//                case .success:
//                    print(tag?.searchHistories)
//                    break
//                }
//            }
//            .store(in: &context.disposeBag)
//
//        case .status:
//            // FIXME:
//            break
//        case .bottomLoader:
//            break
//        }
    }
}
