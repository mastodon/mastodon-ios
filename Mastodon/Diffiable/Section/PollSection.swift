//
//  PollSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import UIKit
import CoreData
import CoreDataStack

enum PollSection {
    case main
}

extension PollSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        managedObjectContext: NSManagedObjectContext
    ) -> UITableViewDiffableDataSource<PollSection, PollItem> {
        return UITableViewDiffableDataSource<PollSection, PollItem>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
           return nil
       }
    }
}
