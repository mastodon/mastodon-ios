// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack
import MastodonCore
import MastodonUI
import UIKit

struct StatusEditHistoryViewModel {
    let status: Status
    let edits: [StatusEdit]
    
    let appContext: AppContext
    let authContext: AuthContext

    func prepareCell(_ cell: StatusEditHistoryTableViewCell, in tableView: UITableView) {
        StatusSection.setupStatusPollDataSource(
            context: appContext,
            authContext: authContext,
            statusView: cell.statusView
        )
        
        cell.statusView.frame.size.width = tableView.frame.width - cell.containerViewHorizontalMargin
        cell.statusViewBottomConstraint.constant = cell.statusView.mediaContainerView.isHidden ? -StatusEditHistoryTableViewCell.horizontalMargin : 0
    }
}
