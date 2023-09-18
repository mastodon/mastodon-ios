//
//  SearchHistoryViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit

extension SearchHistoryViewModel {

    func setupDiffableDataSource(
        collectionView: UICollectionView,
        searchHistorySectionHeaderCollectionReusableViewDelegate: SearchHistorySectionHeaderCollectionReusableViewDelegate
    ) {
        diffableDataSource = SearchHistorySection.diffableDataSource(
            viewModel: self,
            collectionView: collectionView,
            authContext: authContext,
            context: context,
            configuration: SearchHistorySection.Configuration(
                searchHistorySectionHeaderCollectionReusableViewDelegate: searchHistorySectionHeaderCollectionReusableViewDelegate
            )
        )

        var snapshot = NSDiffableDataSourceSnapshot<SearchHistorySection, SearchHistoryItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot, animatingDifferences: false)
        
        searchHistoryFetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                Task {
                    do {
                        let managedObjectContext = self.context.managedObjectContext
                        let items: [SearchHistoryItem] = try await managedObjectContext.perform {
                            var items: [SearchHistoryItem] = []

                            for record in records {
                                guard let searchHistory = record.object(in: managedObjectContext) else { continue }
                                if let user = searchHistory.account {
                                    items.append(.user(.init(objectID: user.objectID)))
                                } else if let hashtag = searchHistory.hashtag {
                                    items.append(.hashtag(.init(objectID: hashtag.objectID)))
                                }
                            }
                            
                            return items
                        }

                        let mostRecentItems = Array(items.prefix(10))
                        var snapshot = NSDiffableDataSourceSnapshot<SearchHistorySection, SearchHistoryItem>()
                        snapshot.appendSections([.main])
                        snapshot.appendItems(mostRecentItems, toSection: .main)
                        await diffableDataSource.apply(snapshot, animatingDifferences: true)
                    } catch {
                        // do nothing
                    }
                }   // end Task
            }
            .store(in: &disposeBag)
    }
    
}
