//
//  SuggestionAccountViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

class SuggestionAccountViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SuggestionAccountViewModel!

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(SuggestionAccountTableViewCell.self, forCellReuseIdentifier: String(describing: SuggestionAccountTableViewCell.self))
        tableView.separatorStyle = .none
        return tableView
    }()

    //TODO: Add "follow all"-footer-cell
    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Scene.SuggestionAccount.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.done,
            target: self,
            action: #selector(SuggestionAccountViewController.doneButtonDidClick(_:))
        )

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            suggestionAccountTableViewCellDelegate: self
        )

        view.backgroundColor = .secondarySystemBackground
        tableView.backgroundColor = .secondarySystemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
}

// MARK: - UITableViewDelegate
extension SuggestionAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewDiffableDataSource = viewModel.tableViewDiffableDataSource else { return }
        guard let item = tableViewDiffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .account(let record):
            guard let account = record.object(in: context.managedObjectContext) else { return }
            let cachedProfileViewModel = CachedProfileViewModel(context: context, authContext: viewModel.authContext, mastodonUser: account)
            _ = coordinator.present(
                scene: .profile(viewModel: cachedProfileViewModel),
                from: self,
                transition: .show
            )
        }
    }
}

// MARK: - AuthContextProvider
extension SuggestionAccountViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - SuggestionAccountTableViewCellDelegate
extension SuggestionAccountViewController: SuggestionAccountTableViewCellDelegate {
    func suggestionAccountTableViewCell(
        _ cell: SuggestionAccountTableViewCell,
        friendshipDidPressed button: UIButton
    ) {
        guard let tableViewDiffableDataSource = viewModel.tableViewDiffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = tableViewDiffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .account(let user):
            Task { @MainActor in
                do {
                    try await DataSourceFacade.responseToUserFollowAction(
                        dependency: self,
                        user: user
                    )
                } catch {
                    // do noting
                }
            }
        }
    }
}

extension SuggestionAccountViewController {
    @objc func doneButtonDidClick(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
