//
//  SearchHistoryUserCollectionViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import Foundation
import CoreDataStack
import MastodonUI
import Combine

extension SearchHistoryUserCollectionViewCell {
    final class ViewModel {
        let value: MastodonUser
        
        let followedUsers: AnyPublisher<[String], Never>
        let blockedUsers: AnyPublisher<[String], Never>
            
        init(value: MastodonUser, followedUsers: AnyPublisher<[String], Never>, blockedUsers: AnyPublisher<[String], Never>) {
            self.value = value
            self.followedUsers = followedUsers
            self.blockedUsers =  blockedUsers
        }
    }
}

extension SearchHistoryUserCollectionViewCell {
    func configure(
        me: MastodonUser?,
        viewModel: ViewModel,
        delegate: UserViewDelegate?
    ) {
        let user = viewModel.value
        
        userView.configure(user: user, delegate: delegate)
        
        guard let me = me else {
            return userView.setButtonState(.none)
        }
        
        if user == me {
            userView.setButtonState(.none)
        } else {
            userView.setButtonState(.loading)
        }
        
        Publishers.CombineLatest(
            viewModel.followedUsers,
            viewModel.blockedUsers
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] followed, blocked in
            if blocked.contains(where: { $0 == user.id }) {
                self?.userView.setButtonState(.blocked)
            } else if followed.contains(where: { $0 == user.id }) {
                self?.userView.setButtonState(.unfollow)
            } else {
                self?.userView.setButtonState(.follow)
            }
            
            self?.setNeedsLayout()
            self?.setNeedsUpdateConstraints()
            self?.layoutIfNeeded()
        }
        .store(in: &_disposeBag)
        
    }
}
