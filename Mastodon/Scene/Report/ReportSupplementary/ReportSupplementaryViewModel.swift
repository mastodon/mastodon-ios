//
//  ReportSupplementaryViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import Combine
import CoreDataStack
import MastodonSDK

class ReportSupplementaryViewModel {
    
    // Input
    var context: AppContext
    let user: ManagedObjectRecord<MastodonUser>
    let selectStatuses: [ManagedObjectRecord<Status>]
    let commentContext = ReportItem.CommentContext()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ReportSection, ReportItem>?
    @Published var isNextButtonEnabled = false
    @Published var isReporting = false
    @Published var isReportSuccess = false
    
    init(
        context: AppContext,
        user: ManagedObjectRecord<MastodonUser>,
        selectStatuses: [ManagedObjectRecord<Status>]
    ) {
        self.context = context
        self.user = user
        self.selectStatuses = selectStatuses
        // end init
        
        commentContext.$comment
            .map { comment -> Bool in
                return !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .assign(to: &$isNextButtonEnabled)
    }
    
}

extension ReportSupplementaryViewModel {
    func report(withComment: Bool) async throws {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        let managedObjectContext = context.managedObjectContext
        let _query: Mastodon.API.Reports.FileReportQuery? = try await managedObjectContext.perform {
            guard let user = self.user.object(in: managedObjectContext) else { return nil }
            let statusIDs = self.selectStatuses.compactMap { record -> Status.ID? in
                guard let status = record.object(in: managedObjectContext) else { return nil }
                return status.id
            }
            return Mastodon.API.Reports.FileReportQuery(
                accountID: user.id,
                statusIDs: statusIDs,
                comment: withComment ? self.commentContext.comment : nil,
                forward: nil
            )
        }
        
        guard let query = _query else { return }

        do {
            isReporting = true
            let _ = try await context.apiService.report(
                query: query,
                authenticationBox: authenticationBox
            )
            isReportSuccess = true
        } catch {
            isReporting = false
            throw error
        }
    }
}
