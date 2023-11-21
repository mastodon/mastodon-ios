//
//  DiscoveryForYouViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-14.
//

import UIKit
import Combine
import MastodonUI
import MastodonCore
import MastodonSDK

final class DiscoveryForYouViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {

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
}

extension DiscoveryForYouViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
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
                if isFetching {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !self.refreshControl.isRefreshing {
                            self.refreshControl.beginRefreshing()
                        }
                    }
                } else {
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
        guard case let .account(account, _) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }

        Task {
            await DataSourceFacade.coordinateToProfileScene(provider: self, account: account)
        }
    }

}

// MARK: - ProfileCardTableViewCellDelegate
extension DiscoveryForYouViewController: ProfileCardTableViewCellDelegate {
    func profileCardTableViewCell(
        _ cell: ProfileCardTableViewCell,
        profileCardView: ProfileCardView,
        relationshipButtonDidPressed button: UIButton
    ) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard case let .account(account, _) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }

        cell.profileCardView.setButtonState(.loading)

        Task {
            let newRelationship = try await DataSourceFacade.responseToUserFollowAction(dependency: self, user: account)

            let isMe = (account.id == authContext.mastodonAuthenticationBox.userID)

            await MainActor.run {
                cell.profileCardView.updateButtonState(with: newRelationship, isMe: isMe)
            }
        }
    }
    
    func profileCardTableViewCell(
        _ cell: ProfileCardTableViewCell,
        profileCardView: ProfileCardView,
        familiarFollowersDashboardViewDidPressed view: FamiliarFollowersDashboardView
    ) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard case let .account(account, _) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }

        coordinator.showLoading()

        Task { [weak self] in

            guard let self else { return }
            do {
                let userID = account.id
                let familiarFollowers = viewModel.familiarFollowers.first(where: { $0.id == userID })?.accounts ?? []
                let relationships = try await context.apiService.relationship(forAccounts: familiarFollowers, authenticationBox: authContext.mastodonAuthenticationBox).value

                let familiarFollowersViewModel = FamiliarFollowersViewModel(
                    context: context,
                    authContext: authContext,
                    accounts: familiarFollowers,
                    relationships: relationships
                )

                coordinator.hideLoading()

                let viewController = coordinator.present(
                    scene: .familiarFollowers(viewModel: familiarFollowersViewModel),
                    from: self,
                    transition: .show
                )

                if let familiarFollowersViewController = viewController as? FamiliarFollowersViewController {
                    familiarFollowersViewController.delegate = self
                }
            } catch {

            }
        }
    }
}

// MARK: ScrollViewContainer
extension DiscoveryForYouViewController: ScrollViewContainer {
    var scrollView: UIScrollView { tableView }
}

extension DiscoveryForYouViewController: FamiliarFollowersViewControllerDelegate {
    func relationshipChanged(_ viewController: UIViewController, account: Mastodon.Entity.Account) {
        Task {
            try? await viewModel.fetch()
        }
    }
}
