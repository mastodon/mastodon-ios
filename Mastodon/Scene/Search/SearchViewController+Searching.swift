//
//  SearchViewController+Searching.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/2.
//

import Foundation
import UIKit

extension SearchViewController {
    func setupSearchingTableView() {
        searchingTableView.delegate = self
        searchingTableView.register(SearchingTableViewCell.self, forCellReuseIdentifier: String(describing: SearchingTableViewCell.self))
        view.addSubview(searchingTableView)
        searchingTableView.constrain([
            searchingTableView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchingTableView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchingTableView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchingTableView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            searchingTableView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        viewModel.isSearching
            .receive(on: DispatchQueue.main)
            .sink {[weak self] isSearching in
                self?.searchingTableView.isHidden = !isSearching
                if !isSearching {
                    self?.searchResultDiffableDataSource = nil
                }
            }
            .store(in: &disposeBag)
        
        viewModel.searchResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchResult in
                guard let self = self else { return }
                let dataSource = SearchResultSection.tableViewDiffableDataSource(for: self.searchingTableView)
                var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
                if let accounts = searchResult?.accounts {
                    snapshot.appendSections([.account])
                    let items = accounts.compactMap { SearchResultItem.account(account: $0) }
                    snapshot.appendItems(items, toSection: .account)
                }
                if let tags = searchResult?.hashtags {
                    snapshot.appendSections([.hashTag])
                    let items = tags.compactMap { SearchResultItem.hashTag(tag: $0) }
                    snapshot.appendItems(items, toSection: .hashTag)
                }
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
                self.searchResultDiffableDataSource = dataSource
            }
            .store(in: &disposeBag)
    }
}

// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        66
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        66
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}
