//
//  UserTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import CoreDataStack
import MastodonUI
import Combine
import MastodonCore
import MastodonSDK

extension UserTableViewCell {
    final class ViewModel {
        let user: MastodonUser
        
        let followedUsers: AnyPublisher<[String], Never>
        let blockedUsers: AnyPublisher<[String], Never>
        let followRequestedUsers: AnyPublisher<[String], Never>
        
        init(user: MastodonUser, followedUsers: AnyPublisher<[String], Never>, blockedUsers: AnyPublisher<[String], Never>, followRequestedUsers: AnyPublisher<[String], Never>) {
            self.user = user
            self.followedUsers = followedUsers
            self.followRequestedUsers = followRequestedUsers
            self.blockedUsers =  blockedUsers
        }
    }
}

extension UserTableViewCell {

    func configure(
        me: MastodonUser,
        tableView: UITableView,
        account: Mastodon.Entity.Account,
        relationship: Mastodon.Entity.Relationship?,
        delegate: UserTableViewCellDelegate?
    ) {
        userView.configure(with: account, relationship: relationship, delegate: delegate)

        let isMe = account.id == me.id
        userView.updateButtonState(with: relationship, isMe: isMe)

        self.delegate = delegate
    }

    func configure(
        me: MastodonUser? = nil,
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: UserTableViewCellDelegate?
    ) {
        userView.configure(user: viewModel.user, delegate: delegate)

        guard let me = me else {
            return userView.setButtonState(.none)
        }

        if viewModel.user == me {
            userView.setButtonState(.none)
        } else {
            userView.setButtonState(.loading)
        }

        Publishers.CombineLatest3(
            viewModel.followedUsers,
            viewModel.followRequestedUsers,
            viewModel.blockedUsers
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] followed, requested, blocked in
            if viewModel.user == me {
                self?.userView.setButtonState(.none)
            } else if blocked.contains(viewModel.user.id) {
                self?.userView.setButtonState(.blocked)
            } else if followed.contains(viewModel.user.id) {
                self?.userView.setButtonState(.unfollow)
            } else if requested.contains(viewModel.user.id) {
                self?.userView.setButtonState(.pending)
            } else if viewModel.user.locked {
                self?.userView.setButtonState(.request)
            } else if viewModel.user != me {
                self?.userView.setButtonState(.follow)
            }
        }
        .store(in: &disposeBag)

        self.delegate = delegate
    }
}

extension UserTableViewCellDelegate where Self: ViewControllerWithDependencies & AuthContextProvider {
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for user: MastodonUser) {
        Task {
            try await DataSourceFacade.responseToUserViewButtonAction(
                dependency: self,
                user: user.asRecord,
                buttonState: state
            )
        }
    }
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for account: Mastodon.Entity.Account, me: MastodonUser?) {
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
            }

        }
    }
}
