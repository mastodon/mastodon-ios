//
//  SearchHistoryViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import Combine
import CoreDataStack
import CommonOSLog

final class SearchHistoryViewModel {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let searchHistoryFetchedResultController: SearchHistoryFetchedResultController

    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchHistorySection, SearchHistoryItem>!

    init(context: AppContext) {
        self.context = context
        self.searchHistoryFetchedResultController = SearchHistoryFetchedResultController(managedObjectContext: context.managedObjectContext)

        // may block main queue by large dataset
        searchHistoryFetchedResultController.objectIDs
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objectIDs in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                let managedObjectContext = self.searchHistoryFetchedResultController.fetchedResultsController.managedObjectContext

                var items: [SearchHistoryItem] = []
                for objectID in objectIDs {
                    guard let searchHistory = try? managedObjectContext.existingObject(with: objectID) as? SearchHistory else { continue }
                    if let account = searchHistory.account {
                        let item: SearchHistoryItem = .account(objectID: account.objectID)
                        guard !items.contains(item) else { continue }
                        items.append(item)
                    } else if let hashtag = searchHistory.hashtag {
                        let item: SearchHistoryItem = .hashtag(objectID: hashtag.objectID)
                        guard !items.contains(item) else { continue }
                        items.append(item)
                    } else {
                        // TODO: status
                    }
                }

                var snapshot = NSDiffableDataSourceSnapshot<SearchHistorySection, SearchHistoryItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)

                diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)

        try? searchHistoryFetchedResultController.fetchedResultsController.performFetch()
    }

}

extension SearchHistoryViewModel {
    func setupDiffableDataSource(
        tableView: UITableView,
        dependency: NeedsDependency
    ) {
        diffableDataSource = SearchHistorySection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency
        )

        var snapshot = NSDiffableDataSourceSnapshot<SearchHistorySection, SearchHistoryItem>()
        snapshot.appendSections([.main])
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension SearchHistoryViewModel {
    func persistSearchHistory(for item: SearchHistoryItem) {
        switch item {
        case .account(let objectID):
            let managedObjectContext = context.backgroundManagedObjectContext
            managedObjectContext.performChanges {
                guard let user = try? managedObjectContext.existingObject(with: objectID) as? MastodonUser else { return }
                if let searchHistory = user.searchHistory {
                    searchHistory.update(updatedAt: Date())
                } else {
                    SearchHistory.insert(into: managedObjectContext, account: user)
                }
            }
            .sink { result in
                // do nothing
            }
            .store(in: &context.disposeBag)

        case .hashtag(let objectID):
            let managedObjectContext = context.backgroundManagedObjectContext
            managedObjectContext.performChanges {
                guard let hashtag = try? managedObjectContext.existingObject(with: objectID) as? Tag else { return }
                if let searchHistory = hashtag.searchHistory {
                    searchHistory.update(updatedAt: Date())
                } else {
                    SearchHistory.insert(into: managedObjectContext, hashtag: hashtag)
                }
            }
            .sink { result in
                // do nothing
            }
            .store(in: &context.disposeBag)

        case .status:
            // FIXME:
            break
        }
    }

    func clearSearchHistory() {
        let managedObjectContext = context.backgroundManagedObjectContext
        managedObjectContext.performChanges {
            let request = SearchHistory.sortedFetchRequest
            let searchHistories = managedObjectContext.safeFetch(request)
            for searchHistory in searchHistories {
                managedObjectContext.delete(searchHistory)
            }
        }
        .sink { result in
            // do nothing
        }
        .store(in: &context.disposeBag)

    }
}
