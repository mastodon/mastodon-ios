//
//  ReportResultViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-8.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log
import UIKit

class ReportResultViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let user: ManagedObjectRecord<MastodonUser>
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ReportSection, ReportItem>?
    
    init(
        context: AppContext,
        user: ManagedObjectRecord<MastodonUser>
    ) {
        self.context = context
        self.user = user
        // end init
    }

}
