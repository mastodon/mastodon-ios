//
//  SearchResultViewController+StatusProvider.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

// MARK: - StatusProvider
extension SearchResultViewController: StatusProvider {

    func status() -> Future<Status?, Never> {
        return Future { promise in promise(.success(nil)) }
    }

    func status(for cell: UITableViewCell?, indexPath: IndexPath?) -> Future<Status?, Never> {
        return Future { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource else {
                assertionFailure()
                promise(.success(nil))
                return
            }
            guard let indexPath = indexPath ?? cell.flatMap({ self.tableView.indexPath(for: $0) }),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                promise(.success(nil))
                return
            }

            switch item {
            case .status(let objectID, _):
                let managedObjectContext = self.viewModel.statusFetchedResultsController.fetchedResultsController.managedObjectContext
                managedObjectContext.perform {
                    let status = managedObjectContext.object(with: objectID) as? Status
                    promise(.success(status))
                }
            default:
                promise(.success(nil))
            }
        }
    }

    func status(for cell: UICollectionViewCell) -> Future<Status?, Never> {
        return Future { promise in promise(.success(nil)) }
    }

    var managedObjectContext: NSManagedObjectContext {
        return self.viewModel.statusFetchedResultsController.fetchedResultsController.managedObjectContext
    }

    var tableViewDiffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>? {
        return nil
    }

    func item(for cell: UITableViewCell?, indexPath: IndexPath?) -> Item? {
        return nil
    }

    func items(indexPaths: [IndexPath]) -> [Item] {
        return []
    }

}

extension SearchResultViewController: UserProvider {}
