//
//  UserTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import MastodonUI
import Combine
import MastodonCore
import MastodonSDK

extension UserTableViewCell {
    final class ViewModel {
        let account: Mastodon.Entity.Account

        let followedUsers: AnyPublisher<[String], Never>
        let blockedUsers: AnyPublisher<[String], Never>
        let followRequestedUsers: AnyPublisher<[String], Never>
        
        init(account: Mastodon.Entity.Account, followedUsers: AnyPublisher<[String], Never>, blockedUsers: AnyPublisher<[String], Never>, followRequestedUsers: AnyPublisher<[String], Never>) {
            self.account = account
            self.followedUsers = followedUsers
            self.followRequestedUsers = followRequestedUsers
            self.blockedUsers =  blockedUsers
        }
    }
}

extension UserTableViewCell {

    func configure(
        me: Mastodon.Entity.Account,
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
}

extension UserTableViewCellDelegate where Self: UIViewController & AuthContextProvider {
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for account: Mastodon.Entity.Account, me: Mastodon.Entity.Account?) {
        Task {
            await MainActor.run { view.setButtonState(.loading) }

            guard let relationship = try await LegacyDataSourceFacade.responseToUserViewButtonAction(
                dependency: self,
                account: account,
                buttonState: state
            ) else { return }

            let isMe: Bool
            if let me {
                isMe = account.id == me.id
            } else {
                isMe = false
            }
            
            await MainActor.run {
                guard let currentDisplayedAccount = view.viewModel.account, relationship.isRelationshipToAccount(currentDisplayedAccount) else { return }
                view.viewModel.relationship = relationship
                view.updateButtonState(with: relationship, isMe: isMe)
            }
        }
    }
}
