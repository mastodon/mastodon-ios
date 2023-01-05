//
//  SearchResultViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import Combine

extension SearchResultViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) {
        diffableDataSource = SearchResultSection.tableViewDiffableDataSource(
            tableView: tableView,
            context: context,
            configuration: .init(
                authContext: authContext,
                statusViewTableViewCellDelegate: statusTableViewCellDelegate
            )
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
        snapshot.appendSections([.main])
        //        snapshot.appendItems(items.value, toSection: .main)    // with initial items
        diffableDataSource.apply(snapshot, animatingDifferences: false)

        Publishers.CombineLatest3(
            statusFetchedResultsController.$records,
            userFetchedResultsController.$records,
            $hashtags
        )
        .map { statusRecords, userRecords, hashtags in
            var items: [SearchResultItem] = []
            
            let userItems = userRecords.map { SearchResultItem.user($0) }
            items.append(contentsOf: userItems)
            
            let hashtagItems = hashtags.map { SearchResultItem.hashtag(tag: $0) }
            items.append(contentsOf: hashtagItems)
            
            let statusItems = statusRecords.map { SearchResultItem.status($0) }
            items.append(contentsOf: statusItems)

            return items
        }
        .assign(to: &$items)
        
        $items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Loading,
                        is State.Fail,
                        is State.Idle:
                        let attribute = SearchResultItem.BottomLoaderAttribute(isEmptyResult: false)
                        snapshot.appendItems([.bottomLoader(attribute: attribute)], toSection: .main)
                    case is State.Fail:
                        break
                    case is State.NoMore:
                        if snapshot.itemIdentifiers.isEmpty {
                            let attribute = SearchResultItem.BottomLoaderAttribute(isEmptyResult: true)
                            snapshot.appendItems([.bottomLoader(attribute: attribute)], toSection: .main)
                        }
                    default:
                        break
                    }
                }
                
                diffableDataSource.defaultRowAnimation = .fade
                diffableDataSource.apply(snapshot) { [weak self] in
                    guard let self = self else { return }
                    self.didDataSourceUpdate.send()
                }
            }
            .store(in: &disposeBag)
    }
    
    
}
