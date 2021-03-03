//
//  PollSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import UIKit
import CoreData
import CoreDataStack

enum PollSection: Equatable, Hashable {
    case main
}

extension PollSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        managedObjectContext: NSManagedObjectContext
    ) -> UITableViewDiffableDataSource<PollSection, PollItem> {
        return UITableViewDiffableDataSource<PollSection, PollItem>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .opion(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PollOptionTableViewCell.self), for: indexPath) as! PollOptionTableViewCell
                managedObjectContext.performAndWait {
                    let option = managedObjectContext.object(with: objectID) as! PollOption
                    PollSection.configure(cell: cell, pollOption: option, itemAttribute: attribute)
                }
                return cell
            }
       }
    }
}

extension PollSection {
    static func configure(
        cell: PollOptionTableViewCell,
        pollOption: PollOption,
        itemAttribute: PollItem.Attribute
    ) {
        cell.optionLabel.text = pollOption.title
        cell.configureCheckmark(state: itemAttribute.voted ? .on : .off)
        
    }
}
