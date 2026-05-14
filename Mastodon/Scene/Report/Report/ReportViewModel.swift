//
//  ReportViewModel.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/19.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import OrderedCollections
import UIKit
import MastodonCore
import MastodonLocalization
import MastodonUI

class ReportViewModel {
    let reportReasonViewModel: ReportReasonViewModel
    let reportServerRulesViewModel: ReportServerRulesViewModel
    let reportStatusViewModel: ReportStatusViewModel
    let reportSupplementaryViewModel: ReportSupplementaryViewModel
    let contentDisplayMode: StatusView.ContentDisplayMode

    // input
    let context: AppContext
    let authenticationBox: MastodonAuthenticationBox
    let account: Mastodon.Entity.Account
    let relationship: Mastodon.Entity.Relationship
    let status: MastodonStatus?
    let collection: Mastodon.Entity.Collection?
    
    // output
    @Published var isReporting = false
    @Published var isReportSuccess = false
    
    @MainActor
    init(
        context: AppContext,
        authenticationBox: MastodonAuthenticationBox,
        account: Mastodon.Entity.Account,
        relationship: Mastodon.Entity.Relationship,
        status: MastodonStatus?,
        collection: Mastodon.Entity.Collection?,
        contentDisplayMode: StatusView.ContentDisplayMode
    ) {
        self.contentDisplayMode = contentDisplayMode
        self.context = context
        self.authenticationBox = authenticationBox
        self.account = account
        self.relationship = relationship
        self.status = status
        self.collection = collection
        self.reportReasonViewModel = ReportReasonViewModel(context: context)
        self.reportServerRulesViewModel = ReportServerRulesViewModel(context: context)
        self.reportStatusViewModel = ReportStatusViewModel(context: context, authenticationBox: authenticationBox, account: account, status: status)
        self.reportSupplementaryViewModel = ReportSupplementaryViewModel(context: context, authenticationBox: authenticationBox, account: account)
        // end init
        
        // setup reason viewModel
        if status != nil {
            reportReasonViewModel.headline = L10n.Scene.Report.StepOne.whatsWrongWithThisPost
        } else {
            Task { @MainActor in
                reportReasonViewModel.headline = L10n.Scene.Report.StepOne.whatsWrongWithThisUsername(account.username)
            }
        }
        
        // bind server rules
        Task { @MainActor in
            do {
                let response = try await APIService.shared.instance(domain: authenticationBox.domain, authenticationBox: authenticationBox)
                    .timeout(3, scheduler: DispatchQueue.main)
                    .singleOutput()
                let rules = response.value.rules ?? []
                reportReasonViewModel.serverRules = rules
                reportServerRulesViewModel.serverRules = rules
            } catch {
                reportReasonViewModel.serverRules = []
                reportServerRulesViewModel.serverRules = []
            }
        }   // end Task
        
        $isReporting
            .assign(to: &reportSupplementaryViewModel.$isBusy)
    }

}

extension ReportViewModel {
    @MainActor
    func report() async throws {
        guard !isReporting else { return }

        let account = self.account
        // the status picker is essential step in report flow
        // only check isSkip or not
        let statusIDs: [MastodonStatus.ID]? = {
            if self.reportStatusViewModel.isSkip {
                let _id: MastodonStatus.ID? = self.reportStatusViewModel.status.flatMap { record -> MastodonStatus.ID? in
                    return record.id
                }
                return _id.flatMap { [$0] } ?? []
            } else {
                return self.reportStatusViewModel.selectStatuses.compactMap { record -> MastodonStatus.ID? in
                    return record.id
                }
            }
        }()
        
        // the user comment is essential step in report flow
        // only check isSkip or not
        let comment: String? = {
            let _comment = self.reportSupplementaryViewModel.isSkip ? nil : self.reportSupplementaryViewModel.commentContext.comment
            if let comment = _comment, !comment.isEmpty {
                return comment
            } else {
                return nil
            }
        }()
        
        // collections can be reported from the menu but will not be shown in the user interface for now
        let collectionIDs: [Mastodon.Entity.Collection.ID]? = {
            guard let collection = self.collection else { return nil }
            return [collection.id]
        }()
        
        let query = Mastodon.API.Reports.FileReportQuery(
            accountID: account.id,
            statusIDs: statusIDs,
            collectionIDs: collectionIDs,
            comment: comment,
            forward: true,
            category: {
                switch self.reportReasonViewModel.selectReason {
                    case .dislike:          return nil
                    case .spam:             return .spam
                    case .violateRule:      return .violation
                    case .other:            return .other
                    case .none:             return nil
                }
            }(),
            ruleIDs: {
                switch self.reportReasonViewModel.selectReason {
                    case .violateRule:
                        let ruleIDs = self.reportServerRulesViewModel.selectRules.map { $0.id }.sorted()
                        return ruleIDs
                    default:
                        return nil
                }
            }()
        )

        do {
            isReporting = true
            let result = try await APIService.shared.report(
                query: query,
                authenticationBox: authenticationBox
            )
            isReportSuccess = result.value
        } catch {
            isReporting = false
            throw error
        }
    }
}
