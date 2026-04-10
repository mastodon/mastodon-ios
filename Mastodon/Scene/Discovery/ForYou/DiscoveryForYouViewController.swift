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
import MastodonLocalization

final class DiscoveryForYouViewController: UIViewController, MediaPreviewableViewController {
    
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
    var authenticationBox: MastodonAuthenticationBox { viewModel.authenticationBox }
}

// MARK: - UITableViewDelegate
extension DiscoveryForYouViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case let .account(account, _) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }

        Task {
            guard let myAccount = authenticationBox.cachedAccount else { return }
            let profile: ProfileType = {
                if account.acctWithDomain == myAccount.acctWithDomain {
                    .me(account)
                } else {
                    .notMe(me: myAccount, displayAccount: account, relationship: nil)
                }
            }()
            sceneCoordinator?.present(scene: .profile(profile), from: self, transition: .show)
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
            let newRelationship = try await LegacyDataSourceFacade.responseToUserFollowAction(dependency: self, account: account)

            let isMe = (account.id == authenticationBox.userID)

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

        self.sceneCoordinator?.showLoading()

        Task { [weak self] in

            guard let self else { return }
            do {
                let userID = account.id

                self.sceneCoordinator?.hideLoading()
                
                let familiarFollowersViewModel = TimelineListViewModel(timeline: .familiarFollowers(userID), navigator: .init(navigationType: .uiKit(self)), asyncRefreshViewModel: AsyncRefreshViewModel())

                _ = self.sceneCoordinator?.present(
                    scene: .familiarFollowers(account, authenticationBox),
                    from: self,
                    transition: .show
                )
            } catch {

            }
        }
    }
}

// MARK: ScrollViewContainer
extension DiscoveryForYouViewController: ScrollViewContainer {
    var scrollView: UIScrollView { tableView }
}
