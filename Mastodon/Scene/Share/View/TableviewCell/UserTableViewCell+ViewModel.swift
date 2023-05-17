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
        
        init(value: Value, followedUsers: AnyPublisher<[String], Never>, blockedUsers: AnyPublisher<[String], Never>) {
            self.value = value
            self.followedUsers = followedUsers
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
            
            Publishers.CombineLatest(
                viewModel.followedUsers,
                viewModel.blockedUsers
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] followed, blocked in
                if blocked.contains(user.id) {
                    self?.userView.setButtonState(.blocked)
                } else if followed.contains(user.id) {
                    self?.userView.setButtonState(.unfollow)
                } else if user != me {
                    self?.userView.setButtonState(.follow)
                }

            }
            .store(in: &disposeBag)
            
        }
        
         self.delegate = delegate
    }
    
}
