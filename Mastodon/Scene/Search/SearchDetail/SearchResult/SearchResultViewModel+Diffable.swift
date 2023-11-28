//
//  SearchResultViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import Combine
import MastodonSDK

extension SearchResultViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate,
        userTableViewCellDelegate: UserTableViewCellDelegate
    ) {
        diffableDataSource = SearchResultSection.tableViewDiffableDataSource(
            tableView: tableView,
            context: context,
            authContext: authContext,
            configuration: .init(
                authContext: authContext,
                statusViewTableViewCellDelegate: statusTableViewCellDelegate,
                userTableViewCellDelegate: userTableViewCellDelegate
            )
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
        snapshot.appendSections([.main])
        //        snapshot.appendItems(items.value, toSection: .main)    // with initial items
        diffableDataSource.apply(snapshot, animatingDifferences: false)

        Publishers.CombineLatest3(
            statusFetchedResultsController.$records,
            $accounts,
            $hashtags
        )
        .map { statusRecords, accounts, hashtags in
            var items: [SearchResultItem] = []

            let accountsWithRelationship: [(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)] = accounts.compactMap { account in
                guard let relationship = self.relationships.first(where: {$0.id == account.id }) else { return (account: account, relationship: nil)}

                return (account: account, relationship: relationship)
            }

            let userItems = accountsWithRelationship.map { SearchResultItem.account($0.account, relationship: $0.relationship) }
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
                        is State.Fail:
                        let attribute = SearchResultItem.BottomLoaderAttribute(isEmptyResult: false)
                        snapshot.appendItems([.bottomLoader(attribute: attribute)], toSection: .main)
                    case is State.NoMore:
                        if snapshot.itemIdentifiers.isEmpty {
                            let attribute = SearchResultItem.BottomLoaderAttribute(isEmptyResult: true)
                            snapshot.appendItems([.bottomLoader(attribute: attribute)], toSection: .main)
                        }
                    case is State.Idle:
                        // do nothing
                        break
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
