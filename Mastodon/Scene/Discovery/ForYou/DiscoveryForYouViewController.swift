//
//  DiscoveryForYouViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-14.
//

import os.log
import UIKit
import Combine
import MastodonUI
import MastodonCore

final class DiscoveryForYouViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "DiscoveryForYouViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: DiscoveryForYouViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    let refreshControl = RefreshControl()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension DiscoveryForYouViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            profileCardTableViewCellDelegate: self
        )
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(DiscoveryForYouViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        viewModel.$isFetching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFetching in
                guard let self = self else { return }
                if !isFetching {
                    self.refreshControl.endRefreshing()
                }
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl.endRefreshing()
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }

}

extension DiscoveryForYouViewController {
    
    @objc private func refreshControlValueChanged(_ sender: RefreshControl) {
        Task {
            try await viewModel.fetch()
        }
    }
    
}

// MARK: - AuthContextProvider
extension DiscoveryForYouViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension DiscoveryForYouViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(indexPath)")
        guard case let .user(record) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }
        guard let user = record.object(in: context.managedObjectContext) else { return }
        let profileViewModel = CachedProfileViewModel(
            context: context,
            authContext: viewModel.authContext,
            mastodonUser: user
        )
        _ = coordinator.present(
            scene: .profile(viewModel: profileViewModel),
            from: self,
            transition: .show
        )
    }

}

// MARK: - ProfileCardTableViewCellDelegate
extension DiscoveryForYouViewController: ProfileCardTableViewCellDelegate {
    func profileCardTableViewCell(
        _ cell: ProfileCardTableViewCell,
        profileCardView: ProfileCardView,
        relationshipButtonDidPressed button: ProfileRelationshipActionButton
    ) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard case let .user(record) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }
        
        Task {
            try await DataSourceFacade.responseToUserFollowAction(
                dependency: self,
                user: record
            )
        }   // end Task
    }
    
    func profileCardTableViewCell(
        _ cell: ProfileCardTableViewCell,
        profileCardView: ProfileCardView,
        familiarFollowersDashboardViewDidPressed view: FamiliarFollowersDashboardView
    ) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard case let .user(record) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }
        guard let user = record.object(in: context.managedObjectContext) else { return }
        
        let userID = user.id
        let _familiarFollowers = viewModel.familiarFollowers.first(where: { $0.id == userID })
        guard let familiarFollowers = _familiarFollowers else {
            assertionFailure()
            return
        }
        
        let familiarFollowersViewModel = FamiliarFollowersViewModel(context: context, authContext: authContext)
        familiarFollowersViewModel.familiarFollowers = familiarFollowers
        _ = coordinator.present(
            scene: .familiarFollowers(viewModel: familiarFollowersViewModel),
            from: self,
            transition: .show
        )
    }
}

// MARK: ScrollViewContainer
extension DiscoveryForYouViewController: ScrollViewContainer {
    var scrollView: UIScrollView { tableView }
}

