//
//  AccountViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import PanModal

final class AccountListViewController: UIViewController, NeedsDependency {

    let logger = Logger(subsystem: "AccountListViewController", category: "UI")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = AccountListViewModel(context: context)

    private(set) lazy var addBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(AccountListViewController.addBarButtonItem(_:))
        )
        return barButtonItem
    }()

    let dragIndicatorView = DragIndicatorView()

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(AccountListTableViewCell.self, forCellReuseIdentifier: String(describing: AccountListTableViewCell.self))
        tableView.register(AddAccountTableViewCell.self, forCellReuseIdentifier: String(describing: AddAccountTableViewCell.self))
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        return tableView
    }()

}

// MARK: - PanModalPresentable
extension AccountListViewController: PanModalPresentable {
    var panScrollable: UIScrollView? { tableView }
    var showDragIndicator: Bool { false }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(300)
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(40)
    }
}

extension AccountListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ThemeService.shared.currentTheme.value.systemBackgroundColor.withAlphaComponent(0.9)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)
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
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            managedObjectContext: context.managedObjectContext
        )
    }

    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemBackgroundColor.withAlphaComponent(0.9)
    }

}

extension AccountListViewController {

    @objc private func addBarButtonItem(_ sender: UIBarButtonItem) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
    }

}

// MARK: - UITableViewDelegate
extension AccountListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .authentication(let objectID):
            assert(Thread.isMainThread)
            let authentication = context.managedObjectContext.object(with: objectID) as! MastodonAuthentication
            context.authenticationService.activeMastodonUser(domain: authentication.domain, userID: authentication.userID)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    guard let self = self else { return }
                    self.coordinator.setup()
                }
                .store(in: &disposeBag)
        case .addAccount:
            // TODO: add dismiss entry for welcome scene
            coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
        }
    }
}
