//
//  ReportViewModel.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/19.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import GameplayKit
import MastodonSDK
import OrderedCollections
import UIKit
import MastodonCore
import MastodonLocalization

class ReportViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let reportReasonViewModel: ReportReasonViewModel
    let reportServerRulesViewModel: ReportServerRulesViewModel
    let reportStatusViewModel: ReportStatusViewModel
    let reportSupplementaryViewModel: ReportSupplementaryViewModel

    // input
    let context: AppContext
    let authContext: AuthContext
    let account: Mastodon.Entity.Account
    let relationship: Mastodon.Entity.Relationship
    let status: MastodonStatus?
    
    // output
    @Published var isReporting = false
    @Published var isReportSuccess = false
    
    @MainActor
    init(
        context: AppContext,
        authContext: AuthContext,
        account: Mastodon.Entity.Account,
        relationship: Mastodon.Entity.Relationship,
        status: MastodonStatus?
    ) {
        self.context = context
        self.authContext = authContext
        self.account = account
        self.relationship = relationship
        self.status = status
        self.reportReasonViewModel = ReportReasonViewModel(context: context)
        self.reportServerRulesViewModel = ReportServerRulesViewModel(context: context)
        self.reportStatusViewModel = ReportStatusViewModel(context: context, authContext: authContext, account: account, status: status)
        self.reportSupplementaryViewModel = ReportSupplementaryViewModel(context: context, authContext: authContext, account: account)
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
                let response = try await context.apiService.instance(domain: authContext.mastodonAuthenticationBox.domain, authenticationBox: authContext.mastodonAuthenticationBox)
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
        let query = Mastodon.API.Reports.FileReportQuery(
            accountID: account.id,
            statusIDs: statusIDs,
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
            let _ = try await context.apiService.report(
                query: query,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            isReportSuccess = true
        } catch {
            isReporting = false
            throw error
        }
    }
}
