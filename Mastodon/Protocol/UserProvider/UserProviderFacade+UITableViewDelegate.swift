//
//  UserProviderFacade+UITableViewDelegate.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import Combine
import CoreDataStack
import MastodonSDK
import os.log
import UIKit

extension UserTableViewCellDelegate where Self: UserProvider {

    func handleTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let user = self.mastodonUser(for: cell)
        UserProviderFacade.coordinatorToUserProfileScene(provider: self, user: user)
    }
    
}
