//
//  SearchHistoryViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import UIKit
import Combine
import CoreDataStack

final class SearchHistoryViewController: UIViewController, NeedsDependency {

    var disposeBag = Set<AnyCancellable>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var viewModel: SearchHistoryViewModel!

    let searchHistoryTableHeaderView = SearchHistoryTableHeaderView()
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: String(describing: SearchResultTableViewCell.self))
//        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        return tableView
    }()

}

extension SearchHistoryViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            dependency: self
        )

        searchHistoryTableHeaderView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }

}

extension SearchHistoryViewController {
    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemGroupedBackgroundColor
    }
}

// MARK: - UITableViewDelegate
extension SearchHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return searchHistoryTableHeaderView
        default:
            return UIView()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return UITableView.automaticDimension
        default:
            return .leastNonzeroMagnitude
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        viewModel.persistSearchHistory(for: item)

        switch item {
        case .account(let objectID):
            guard let user = try? viewModel.searchHistoryFetchedResultController.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? MastodonUser else { return }
            let profileViewModel = CachedProfileViewModel(context: context, mastodonUser: user)
            coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
        case .hashtag(let objectID):
            guard let hashtag = try? viewModel.searchHistoryFetchedResultController.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? Tag else { return }
            let hashtagViewModel = HashtagTimelineViewModel(context: context, hashtag: hashtag.name)
            coordinator.present(scene: .hashtagTimeline(viewModel: hashtagViewModel), from: self, transition: .show)
        case .status(let objectID, _):
            guard let status = try? viewModel.searchHistoryFetchedResultController.fetchedResultsController.managedObjectContext.existingObject(with: objectID) as? Status else { return }
            let threadViewModel = CachedThreadViewModel(context: context, status: status)
            coordinator.present(scene: .thread(viewModel: threadViewModel), from: self, transition: .show)
        }
    }
}

// MARK: - SearchHistoryTableHeaderViewDelegate
extension SearchHistoryViewController: SearchHistoryTableHeaderViewDelegate {
    func searchHistoryTableHeaderView(_ searchHistoryTableHeaderView: SearchHistoryTableHeaderView, clearSearchHistoryButtonDidPressed button: UIButton) {
        viewModel.clearSearchHistory()
    }
}
