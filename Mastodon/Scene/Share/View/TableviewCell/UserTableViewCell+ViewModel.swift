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

extension UserTableViewCell {
    final class ViewModel {
        let value: Value
        
        let followedUsers: AnyPublisher<[String], Never>
        let blockedUsers: AnyPublisher<[String], Never>
        let followRequestedUsers: AnyPublisher<[String], Never>
        
        init(value: Value, followedUsers: AnyPublisher<[String], Never>, blockedUsers: AnyPublisher<[String], Never>, followRequestedUsers: AnyPublisher<[String], Never>) {
            self.value = value
            self.followedUsers = followedUsers
            self.followRequestedUsers = followRequestedUsers
            self.blockedUsers =  blockedUsers
        }
        
        enum Value {
            case user(MastodonUser)
            // case status(Status)
        }
    }
}

extension UserTableViewCell {

    func configure(
        me: MastodonUser?,
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: UserTableViewCellDelegate?
    ) {
        switch viewModel.value {
        case .user(let user):
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
                if blocked.contains(user.id) {
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
            .store(in: &disposeBag)
            
        }
        
         self.delegate = delegate
    }
    
}
