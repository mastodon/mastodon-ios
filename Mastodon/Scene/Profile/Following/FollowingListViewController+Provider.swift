//
//  FollowingListViewController+Provider.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-2.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

extension FollowingListViewController: UserProvider {
    
    func mastodonUser() -> Future<MastodonUser?, Never> {
        Future { promise in
            promise(.success(nil))
        }
    }
    
    func mastodonUser(for cell: UITableViewCell?) -> Future<MastodonUser?, Never> {
        Future { [weak self] promise in
            guard let self = self else { return }
            guard let diffableDataSource = self.viewModel.diffableDataSource else {
                assertionFailure()
                promise(.success(nil))
                return
            }
            guard let cell = cell,
                  let indexPath = self.tableView.indexPath(for: cell),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                      promise(.success(nil))
                      return
                  }
            
            let managedObjectContext = self.viewModel.userFetchedResultsController.fetchedResultsController.managedObjectContext
            
            switch item {
            case .follower(let objectID),
                 .following(let objectID):
                managedObjectContext.perform {
                    let user = managedObjectContext.object(with: objectID) as? MastodonUser
                    promise(.success(user))
                }
            case .bottomLoader, .bottomHeader:
                promise(.success(nil))
            }
        }
    }
}
