//
//  ReportSection.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import AVKit
import os.log

enum ReportSection: Equatable, Hashable {
    case main
}

extension ReportSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        managedObjectContext: NSManagedObjectContext,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        reportdStatusDelegate: ReportedStatusTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<ReportSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) {[
            weak dependency
        ] tableView, indexPath, item -> UITableViewCell? in
            guard let dependency = dependency else { return UITableViewCell() }

            switch item {
            case .status(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReportedStatusTableViewCell.self), for: indexPath) as! ReportedStatusTableViewCell
                let activeMastodonAuthenticationBox = dependency.context.authenticationService.activeMastodonAuthenticationBox.value
                let requestUserID = activeMastodonAuthenticationBox?.userID ?? ""
                managedObjectContext.performAndWait {
                    let status = managedObjectContext.object(with: objectID) as! Status
                    StatusSection.configure(
                        cell: cell,
                        dependency: dependency,
                        readableLayoutFrame: tableView.readableContentGuide.layoutFrame,
                        timestampUpdatePublisher: timestampUpdatePublisher,
                        status: status,
                        requestUserID: requestUserID,
                        statusItemAttribute: attribute
                    )
                }
                
                let isSelected = reportdStatusDelegate.reportedStatus(cell: cell, isSelected: indexPath)
                cell.setupSelected(isSelected)
                return cell
            default:
                return nil
            }
        }
    }
}
