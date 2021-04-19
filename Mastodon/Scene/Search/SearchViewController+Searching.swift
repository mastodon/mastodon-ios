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
        searchingTableView.register(SearchingTableViewCell.self, forCellReuseIdentifier: String(describing: SearchingTableViewCell.self))
        searchingTableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        searchingTableView.estimatedRowHeight = 66
        searchingTableView.rowHeight = 66
        view.addSubview(searchingTableView)
        searchingTableView.delegate = self
        searchingTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchingTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            searchingTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchingTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchingTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
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
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fill
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        searchHeader.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: searchHeader.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: searchHeader.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: searchHeader.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: searchHeader.bottomAnchor)
        ])
        recentSearchesLabel.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(recentSearchesLabel)
        clearSearchHistoryButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(clearSearchHistoryButton)
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let diffableDataSource = viewModel.searchResultDiffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.searchResultItemDidSelected(item: item, from: self)
    }
}
