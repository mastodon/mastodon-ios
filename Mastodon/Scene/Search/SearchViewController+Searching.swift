//
//  SearchViewController+Searching.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/2.
//

import Foundation
import MastodonSDK
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
            searchingTableView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        searchingTableView.tableFooterView = UIView()
        viewModel.isSearching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSearching in
                self?.searchingTableView.isHidden = !isSearching
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
