//
//  ReportViewModel.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/19.
//

import Combine
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
    let user: Mastodon.Entity.Account
    let status: Mastodon.Entity.Status?
    
    // output
    @Published var isReporting = false
    @Published var isReportSuccess = false
    
    init(
        context: AppContext,
        authContext: AuthContext,
        user: Mastodon.Entity.Account,
        status: Mastodon.Entity.Status?
    ) {
        self.context = context
        self.authContext = authContext
        self.user = user
        self.status = status
        self.reportReasonViewModel = ReportReasonViewModel(context: context)
        self.reportServerRulesViewModel = ReportServerRulesViewModel(context: context)
        self.reportStatusViewModel = ReportStatusViewModel(context: context, authContext: authContext, user: user, status: status)
        self.reportSupplementaryViewModel = ReportSupplementaryViewModel(context: context, authContext: authContext, user: user)
        // end init
        
        // setup reason viewModel
        if status != nil {
            reportReasonViewModel.headline = L10n.Scene.Report.StepOne.whatsWrongWithThisPost
        } else {
            Task { @MainActor in
                reportReasonViewModel.headline = L10n.Scene.Report.StepOne.whatsWrongWithThisUsername(user.acctWithDomain)
            }   // end Task
        }
        
        // bind server rules
        Task { @MainActor in
            do {
                let response = try await context.apiService.instance(domain: authContext.mastodonAuthenticationBox.domain)
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

        // the status picker is essential step in report flow
        // only check isSkip or not
        let statusIDs: [Mastodon.Entity.Status.ID]? = {
            if self.reportStatusViewModel.isSkip {
                let _id: Mastodon.Entity.Status.ID? = self.reportStatusViewModel.status.flatMap { record -> Mastodon.Entity.Status.ID? in
                    return record.id
                }
                return _id.flatMap { [$0] } ?? []
            } else {
                return self.reportStatusViewModel.selectStatuses.compactMap { record -> Mastodon.Entity.Status.ID? in
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
            accountID: user.id,
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
            #if DEBUG
            try await Task.sleep(nanoseconds: .second * 3)
            #else
            let _ = try await context.apiService.report(
                query: query,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            #endif
            isReportSuccess = true
        } catch {
            isReporting = false
            throw error
        }
    }
}
