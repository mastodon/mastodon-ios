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
import MastodonAsset
import MastodonLocalization
import MastodonCore

final class AccountListViewController: UIViewController, NeedsDependency {

    let logger = Logger(subsystem: "AccountListViewController", category: "UI")

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

    var hasLoaded = false
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(AccountListTableViewCell.self, forCellReuseIdentifier: String(describing: AccountListTableViewCell.self))
        tableView.register(AddAccountTableViewCell.self, forCellReuseIdentifier: String(describing: AddAccountTableViewCell.self))
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()

}

// MARK: - PanModalPresentable
extension AccountListViewController: PanModalPresentable {
    var panScrollable: UIScrollView? { tableView }
    var showDragIndicator: Bool { false }
    
    var shortFormHeight: PanModalHeight {
        func calculateHeight(of numberOfItems: Int) -> CGFloat {
            return CGFloat(numberOfItems * 60 + 64)
        }
        
        if hasLoaded {
            let height = calculateHeight(of: viewModel.diffableDataSource.snapshot().numberOfItems)
            return .contentHeight(CGFloat(height))
        }
        
        let request = MastodonAuthentication.sortedFetchRequest
        let authenticationCount = (try? context.managedObjectContext.count(for: request)) ?? 0
        
        let count = authenticationCount + 1
        let height = calculateHeight(of: count)
        return .contentHeight(height)
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(0)
    }
}

extension AccountListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
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
        
        viewModel.dataSourceDidUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak presentingViewController] in
                guard let self = self else { return }
                
                // the presentingViewController may deinit.
                // Hold it and check the window to prevent PanModel crash
                guard let _ = presentingViewController else { return }
                guard self.view.window != nil else { return }
                
                self.hasLoaded = true
                self.panModalSetNeedsLayoutUpdate()     // <<< may crash the app
                self.panModalTransition(to: .shortForm)
            }
            .store(in: &disposeBag)
    }

    private func setupBackgroundColor(theme: Theme) {
        let backgroundColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceLevel {
            case .elevated where traitCollection.userInterfaceStyle == .dark:
                return theme.systemElevatedBackgroundColor
            default:
                return theme.systemBackgroundColor.withAlphaComponent(0.9)
            }
        }
        view.backgroundColor = backgroundColor
    }

}

extension AccountListViewController {

    @objc private func addBarButtonItem(_ sender: UIBarButtonItem) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        _ = coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
    }

    override func accessibilityPerformEscape() -> Bool {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        dismiss(animated: true, completion: nil)
        return true
    }

}

// MARK: - UITableViewDelegate
extension AccountListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .authentication(let record):
            assert(Thread.isMainThread)
            guard let authentication = record.object(in: context.managedObjectContext) else { return }
            Task { @MainActor in
                let isActive = try await context.authenticationService.activeMastodonUser(domain: authentication.domain, userID: authentication.userID)
                guard isActive else { return }
                self.coordinator.setup()
            }   // end Task
        case .addAccount:
            // TODO: add dismiss entry for welcome scene
            _ = coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
        }
    }
}
