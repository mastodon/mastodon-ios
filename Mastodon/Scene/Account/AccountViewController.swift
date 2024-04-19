//
//  AccountViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//

import UIKit
import Combine
import CoreDataStack
import MastodonAsset
import MastodonLocalization
import MastodonCore

final class AccountListViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: AccountListViewModel!

    private(set) lazy var addBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(AccountListViewController.addBarButtonItem(_:))
        )
        return barButtonItem
    }()

    lazy var dragIndicatorView = DragIndicatorView { [weak self] in
        self?.dismiss(animated: true, completion: nil)
    }

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(AccountListTableViewCell.self, forCellReuseIdentifier: String(describing: AccountListTableViewCell.self))
        tableView.register(AddAccountTableViewCell.self, forCellReuseIdentifier: String(describing: AddAccountTableViewCell.self))
        tableView.register(LogoutOfAllAccountsCell.self, forCellReuseIdentifier: LogoutOfAllAccountsCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        return tableView
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portraitOnPhone
    }
}

extension AccountListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .secondarySystemGroupedBackground
        navigationItem.rightBarButtonItem = addBarButtonItem

        dragIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dragIndicatorView)
        NSLayoutConstraint.activate([
            dragIndicatorView.topAnchor.constraint(equalTo: view.topAnchor),
            dragIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dragIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dragIndicatorView.heightAnchor.constraint(equalToConstant: DragIndicatorView.height).priority(.required - 1),
        ])

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: dragIndicatorView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.delegate = self
        viewModel.setupDiffableDataSource(tableView: tableView)
    }
}

extension AccountListViewController {

    @objc private func addBarButtonItem(_ sender: UIBarButtonItem) {
        _ = coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true, completion: nil)
        return true
    }

}

// MARK: - UITableViewDelegate
extension AccountListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let diffableDataSource = viewModel.diffableDataSource,
              let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }

        switch item {
        case .authentication(let record):
            let logoutAction = UIContextualAction(style: .destructive, title: L10n.Scene.AccountList.logout, handler: { [weak self] action, view, completion in
                guard let self else { return }

                UserDefaults.shared.setNotificationCountWithAccessToken(accessToken: record.userAccessToken, value: 0)

                Task { @MainActor in
                    do {
                        try await self.viewModel.context.authenticationService.signOutMastodonUser(authentication: record)

                        let userIdentifier = record
                        FileManager.default.invalidateHomeTimelineCache(for: userIdentifier)
                        FileManager.default.invalidateNotificationsAll(for: userIdentifier)
                        FileManager.default.invalidateNotificationsMentions(for: userIdentifier)
                        self.coordinator.setup()

                    } catch {
                        assertionFailure("Failed to delete Authentication: \(error)")
                    }

                }
            })
            logoutAction.image = UIImage(systemName: "rectangle.portrait.and.arrow.forward")

            let swipeConfiguration = UISwipeActionsConfiguration(actions: [logoutAction])
            swipeConfiguration.performsFirstActionWithFullSwipe = false
            return swipeConfiguration
        case .addAccount, .logoutOfAllAccounts:
            return nil
        }

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let diffableDataSource = viewModel.diffableDataSource,
              let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .authentication(let record):
            assert(Thread.isMainThread)
            Task { @MainActor in
                let isActive = try await context.authenticationService.activeMastodonUser(domain: record.domain, userID: record.userID)
                guard isActive else { return }
                self.coordinator.setup()
            }   // end Task
        case .addAccount:
            // TODO: add dismiss entry for welcome scene
            _ = coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
        case .logoutOfAllAccounts:
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            let logoutAction = UIAlertAction(title: L10n.Scene.AccountList.logoutAllAccounts, style: .destructive) { _ in
                Task { @MainActor in
                    self.coordinator.showLoading()
                    for authenticationBox in self.context.authenticationService.mastodonAuthenticationBoxes {
                        try? await self.context.authenticationService.signOutMastodonUser(authenticationBox: authenticationBox)
                    }
                    self.coordinator.hideLoading()

                    self.coordinator.setup()
                }
            }

            alert.addAction(logoutAction)

            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .default)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        }
    }
}
