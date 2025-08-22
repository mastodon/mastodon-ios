// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack
import MastodonCore
import MastodonUI
import UIKit
import MastodonSDK

struct StatusEditHistoryViewModel {
    let status: Mastodon.Entity.Status
    let edits: [Mastodon.Entity.StatusEdit]
    
    let appContext: AppContext
    let authenticationBox: MastodonAuthenticationBox

    func prepareCell(_ cell: StatusEditHistoryTableViewCell, in tableView: UITableView) {
        StatusSection.setupStatusPollHistoryDataSource(
            context: appContext,
            authenticationBox: authenticationBox,
            statusView: cell.statusHistoryView.statusView
        )
        
        cell.statusHistoryView.statusView.frame.size.width = tableView.frame.width - cell.containerViewHorizontalMargin
        cell.statusViewBottomConstraint?.constant = cell.statusHistoryView.statusView.mediaContainerView.isHidden ? -StatusEditHistoryTableViewCell.verticalMargin : 0
    }
}
