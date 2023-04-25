//
//  UserTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import CoreDataStack

extension UserTableViewCell {
    final class ViewModel {
        let value: Value

        init(value: Value) {
            self.value = value
        }
        
        enum Value {
            case user(MastodonUser)
            // case status(Status)
        }
    }
}

extension UserTableViewCell {

    func configure(
        meUserID: MastodonUser.ID?,
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: UserTableViewCellDelegate?
    ) {
        switch viewModel.value {
        case .user(let user):
            userView.configure(user: user, delegate: delegate)
            
            if user.id == meUserID {
                userView.setButtonState(.none)
            } else if user.blockingBy.contains(where: { $0.id == meUserID }) {
                userView.setButtonState(.blocked)
            } else if user.followingBy.contains(where: { $0.id == meUserID }) {
                userView.setButtonState(.unfollow)
            } else {
                userView.setButtonState(.follow)
            }
            
        }
        
         self.delegate = delegate
    }
    
}
