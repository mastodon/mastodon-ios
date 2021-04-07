//
//  ProfileViewController+UserProvider.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import Foundation
import Combine
import CoreDataStack

extension ProfileViewController: UserProvider {
    
    func mastodonUser() -> Future<MastodonUser?, Never> {
        return Future { promise in
            promise(.success(self.viewModel.mastodonUser.value))
        }
    }
    
}
