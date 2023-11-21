//
//  FamiliarFollowersViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import Combine
import MastodonCore
import MastodonLocalization
import MastodonUI
import MastodonSDK
import CoreDataStack

protocol FamiliarFollowersViewControllerDelegate: AnyObject {
    func relationshipChanged(_ viewController: UIViewController, account: Mastodon.Entity.Account)
}

final class FamiliarFollowersViewController: UIViewController, NeedsDependency {

    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
    let viewModel: FamiliarFollowersViewModel
    weak var delegate: FamiliarFollowersViewControllerDelegate?

    let tableView: UITableView

    init(viewModel: FamiliarFollowersViewModel, context: AppContext, coordinator: SceneCoordinator) {
        self.viewModel = viewModel
        self.context = context
        self.coordinator = coordinator

        tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        super.init(nibName: nil, bundle: nil)

        title = L10n.Scene.Familiarfollowers.title

        view.backgroundColor = .secondarySystemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            userTableViewCellDelegate: self
        )
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
        viewModel.viewWillAppear()
    }
    
}

// MARK: - AuthContextProvider
extension FamiliarFollowersViewController: AuthContextProvider {
    var authContext: AuthContext {
        viewModel.authContext
    }
}

// MARK: - UITableViewDelegate
extension FamiliarFollowersViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:FamiliarFollowersViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    // sourcery:end
}

// MARK: - UserTableViewCellDelegate
extension FamiliarFollowersViewController: UserTableViewCellDelegate {
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for user: MastodonUser) { }
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for account: Mastodon.Entity.Account, me: MastodonUser?) {

        // Can we call the default implementation somehow? Maybe add a FollowAction-class with a completion-block?
        Task {
            await MainActor.run { view.setButtonState(.loading) }

            try await DataSourceFacade.responseToUserViewButtonAction(
                dependency: self,
                user: account,
                buttonState: state
            )

            // this is a dirty hack to give the backend enough time to process the relationship-change
            // Otherwise the relationship might still be `pending`
            try await Task.sleep(for: .seconds(1))

            let relationship = try await self.context.apiService.relationship(forAccounts: [account], authenticationBox: authContext.mastodonAuthenticationBox).value.first

            let isMe: Bool
            if let me {
                isMe = account.id == me.id
            } else {
                isMe = false
            }

            await MainActor.run {
                view.viewModel.relationship = relationship
                view.updateButtonState(with: relationship, isMe: isMe)

                delegate?.relationshipChanged(self, account: account)
            }
        }
    }

}

//MARK: - DataSourceProvider
extension FamiliarFollowersViewController: DataSourceProvider {
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        var _indexPath = source.indexPath
        if _indexPath == nil, let cell = source.tableViewCell {
            _indexPath = await self.indexPath(for: cell)
        }
        guard let indexPath = _indexPath else { return nil }

        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }

        switch item {
            case .account(let account, relationship: let relationship):
                return .account(account: account, relationship: relationship)

            default:
                return nil
        }
    }

    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

