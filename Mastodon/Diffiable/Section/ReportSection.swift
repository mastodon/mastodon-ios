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
        timestampUpdatePublisher: AnyPublisher<Date, Never>
    ) -> UITableViewDiffableDataSource<ReportSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) {[
            weak dependency
        ] tableView, indexPath, item -> UITableViewCell? in
            guard let dependency = dependency else { return UITableViewCell() }

            switch item {
            case .reportStatus(let objectID, let attribute):
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
                
                // defalut to select the report status
                if attribute.isSelected {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
                
                return cell
            default:
                return nil
            }
        }
    }
}
