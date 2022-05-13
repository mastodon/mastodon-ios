//
//  SearchViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import UIKit
import MastodonSDK

//extension SearchViewModel {
//    
//    func setupDiffableDataSource(
//        collectionView: UICollectionView
//    ) {
//        diffableDataSource = SearchSection.diffableDataSource(
//            collectionView: collectionView,
//            context: context
//        )
//        
//        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
//        snapshot.appendSections([.trend])
//        diffableDataSource?.apply(snapshot)
//        
//        $hashtags
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] hashtags in
//                guard let self = self else { return }
//                guard let diffableDataSource = self.diffableDataSource else { return }
//                
//                var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
//                snapshot.appendSections([.trend])
//                
//                let trendItems = hashtags.map { SearchItem.trend($0) }
//                snapshot.appendItems(trendItems, toSection: .trend)
//                
//                diffableDataSource.apply(snapshot)
//            }
//            .store(in: &disposeBag)
//    }
//    
//}
