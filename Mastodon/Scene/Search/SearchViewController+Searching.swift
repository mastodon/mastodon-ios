//
//  SearchViewController+Searching.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/2.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import OSLog
import UIKit

extension SearchViewController {
    func setupSearchingTableView() {
        searchingTableView.delegate = self
        searchingTableView.register(SearchingTableViewCell.self, forCellReuseIdentifier: String(describing: SearchingTableViewCell.self))
        searchingTableView.register(SearchBottomLoader.self, forCellReuseIdentifier: String(describing: SearchBottomLoader.self))
        view.addSubview(searchingTableView)
        searchingTableView.constrain([
            searchingTableView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchingTableView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchingTableView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchingTableView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            searchingTableView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        searchingTableView.tableFooterView = UIView()
        viewModel.isSearching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSearching in
                self?.searchingTableView.isHidden = !isSearching
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(
            viewModel.isSearching,
            viewModel.searchText
        )
        .sink { [weak self] isSearching, text in
            guard let self = self else { return }
            if isSearching, text.isEmpty {
                self.searchingTableView.tableHeaderView = self.searchHeader
            } else {
                self.searchingTableView.tableHeaderView = nil
            }
        }
        .store(in: &disposeBag)
    }

    func setupSearchHeader() {
        searchHeader.addSubview(recentSearchesLabel)
        recentSearchesLabel.constrain([
            recentSearchesLabel.constraint(.leading, toView: searchHeader, constant: 16),
            recentSearchesLabel.constraint(.centerY, toView: searchHeader)
        ])

        searchHeader.addSubview(clearSearchHistoryButton)
        recentSearchesLabel.constrain([
            searchHeader.trailingAnchor.constraint(equalTo: clearSearchHistoryButton.trailingAnchor, constant: 16),
            clearSearchHistoryButton.constraint(.centerY, toView: searchHeader)
        ])

        clearSearchHistoryButton.addTarget(self, action: #selector(SearchViewController.clearAction(_:)), for: .touchUpInside)
    }
}

extension SearchViewController {
    @objc func clearAction(_ sender: UIButton) {
        viewModel.deleteSearchHistory()
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.searchResultDiffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.searchResultItemDidSelected(item: item, from: self)
    }
}
