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
        // prefetch reply toot
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        let domain = activeMastodonAuthenticationBox.domain
        
        var statusObjectIDs: [NSManagedObjectID] = []
        for item in items(indexPaths: indexPaths) {
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let homeTimelineIndex = managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                statusObjectIDs.append(homeTimelineIndex.toot.objectID)
            case .toot(let objectID, _):
                statusObjectIDs.append(objectID)
            default:
                continue
            }
        }
        
        let backgroundManagedObjectContext = context.backgroundManagedObjectContext
        backgroundManagedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            for objectID in statusObjectIDs {
                let toot = backgroundManagedObjectContext.object(with: objectID) as! Toot
                guard let replyToID = toot.inReplyToID, toot.replyTo == nil else {
                    // skip
                    continue
                }
                self.context.statusPrefetchingService.prefetchReplyTo(
                    domain: domain,
                    statusObjectID: toot.objectID,
                    statusID: toot.id,
                    replyToStatusID: replyToID,
                    authorizationBox: activeMastodonAuthenticationBox
                )
            }
        }
    }
}
