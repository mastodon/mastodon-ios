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

extension UserTableViewCellDelegate where Self: NeedsDependency & AuthContextProvider {
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for user: MastodonUser) {
        Task {
            try await DataSourceFacade.responseToUserViewButtonAction(
                dependency: self,
                user: user.asRecord,
                buttonState: state
            )
        }
    }

    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for user: Mastodon.Entity.Account) {
        Task {
            try await DataSourceFacade.responseToUserViewButtonAction(
                dependency: self,
                user: user,
                buttonState: state
            )
        }
    }

}
