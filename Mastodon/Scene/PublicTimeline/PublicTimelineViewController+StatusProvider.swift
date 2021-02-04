//
//  PublicTimelineViewController+StatusProvider.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonSDK

// MARK: - StatusProvider
extension PublicTimelineViewController {
    
    func toot() -> Future<Toot?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
    func toot(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Toot?, Never> {
        return Future { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource else {
                assertionFailure()
                promise(.success(nil))
                return
            }
            guard let indexPath = indexPath ?? self.tableView.indexPath(for: cell),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                promise(.success(nil))
                return
            }
            
            switch item {
            case .toot(let objectID):
                let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
                managedObjectContext.perform {
                    let toot = managedObjectContext.object(with: objectID) as? Toot
                    promise(.success(toot))
                }
            default:
                promise(.success(nil))
            }
        }
    }
    
    func toot(for cell: UICollectionViewCell) -> Future<Toot?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
}
