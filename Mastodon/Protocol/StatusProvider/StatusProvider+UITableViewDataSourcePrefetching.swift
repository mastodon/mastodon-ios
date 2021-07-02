//
//  StatusProvider+UITableViewDataSourcePrefetching.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import UIKit
import CoreData
import CoreDataStack

extension StatusTableViewCellDelegate where Self: StatusProvider {
    func handleTableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // prefetch reply status
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        let domain = activeMastodonAuthenticationBox.domain
        let items = self.items(indexPaths: indexPaths)

        let managedObjectContext = context.managedObjectContext
        managedObjectContext.perform { [weak self] in
            guard let self = self else { return }

            var statuses: [Status] = []
            for item in items {
                switch item {
                case .homeTimelineIndex(let objectID, _):
                    guard let homeTimelineIndex = try? managedObjectContext.existingObject(with: objectID) as? HomeTimelineIndex else { continue }
                    statuses.append(homeTimelineIndex.status)
                case .status(let objectID, _):
                    guard let status = try? managedObjectContext.existingObject(with: objectID) as? Status else { continue }
                    statuses.append(status)
                default:
                    continue
                }
            }

            for status in statuses {
                if let replyToID = status.inReplyToID, status.replyTo == nil {
                    self.context.statusPrefetchingService.prefetchReplyTo(
                        domain: domain,
                        statusObjectID: status.objectID,
                        statusID: status.id,
                        replyToStatusID: replyToID,
                        authorizationBox: activeMastodonAuthenticationBox
                    )
                }
            }   // end for in
        }   // end context.perform
    }   // end func
}
