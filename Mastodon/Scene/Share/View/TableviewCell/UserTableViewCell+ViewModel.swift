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
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: UserTableViewCellDelegate?
    ) {
        switch viewModel.value {
        case .user(let user):
            userView.configure(user: user)
        }
        
         self.delegate = delegate
    }
    
}
