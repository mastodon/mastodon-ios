// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack
import MastodonCore
import MastodonUI

struct StatusEditHistoryViewModel {
    let status: Status
    let edits: [StatusEdit]
    
    let appContext: AppContext
    let authContext: AuthContext

    func prepareCell(_ cell: StatusEditHistoryTableViewCell) {
        StatusSection.setupStatusPollDataSource(
            context: appContext,
            authContext: authContext,
            statusView: cell.statusView
        )
    }
}
