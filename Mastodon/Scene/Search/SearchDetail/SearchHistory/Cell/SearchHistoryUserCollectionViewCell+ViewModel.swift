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
        let followRequestedUsers: AnyPublisher<[String], Never>

        init(value: MastodonUser, followedUsers: AnyPublisher<[String], Never>, blockedUsers: AnyPublisher<[String], Never>, followRequestedUsers: AnyPublisher<[String], Never>) {
            self.value = value
            self.followedUsers = followedUsers
            self.followRequestedUsers = followRequestedUsers
            self.blockedUsers =  blockedUsers
        }
    }
}

extension SearchHistoryUserCollectionViewCell {
    func configure(
        me: MastodonUser?,
        viewModel: ViewModel,
        delegate: SearchHistorySectionHeaderCollectionReusableViewDelegate?
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
        
        Publishers.CombineLatest3(
            viewModel.followedUsers,
            viewModel.followRequestedUsers,
            viewModel.blockedUsers
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] followed, requested, blocked in
            if user == me {
                self?.userView.setButtonState(.none)
            } else if blocked.contains(user.id) {
                self?.userView.setButtonState(.blocked)
            } else if followed.contains(user.id) {
                self?.userView.setButtonState(.unfollow)
            } else if requested.contains(user.id) {
                self?.userView.setButtonState(.pending)
            } else if user.locked {
                self?.userView.setButtonState(.request)
            } else if user != me {
                self?.userView.setButtonState(.follow)
            }
        }
        .store(in: &_disposeBag)
    }
}
