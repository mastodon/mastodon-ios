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

        $items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in

                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                let searchItems: [SearchHistoryItem] = items.compactMap {
                    if let account = $0.account {
                        return .account(account)
                    } else if let tag = $0.hashtag {
                        return .hashtag(tag)
                    } else {
                        return nil
                    }
                }

                let mostRecentItems = Array(searchItems.prefix(10))
                var snapshot = NSDiffableDataSourceSnapshot<SearchHistorySection, SearchHistoryItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(mostRecentItems, toSection: .main)
                diffableDataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &disposeBag)
    }
}
