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
import os.log
import UIKit
import MastodonLocalization

class ReportViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let reportReasonViewModel: ReportReasonViewModel
    let reportServerRulesViewModel: ReportServerRulesViewModel
    let reportStatusViewModel: ReportStatusViewModel
    let reportSupplementaryViewModel: ReportSupplementaryViewModel

    // input
    let context: AppContext
    let user: ManagedObjectRecord<MastodonUser>
    let status: ManagedObjectRecord<Status>?
    
    // output
    @Published var isReporting = false
    @Published var isReportSuccess = false
    
    init(
        context: AppContext,
        user: ManagedObjectRecord<MastodonUser>,
        status: ManagedObjectRecord<Status>?
    ) {
        self.context = context
        self.user = user
        self.status = status
        self.reportReasonViewModel = ReportReasonViewModel(context: context)
        self.reportServerRulesViewModel = ReportServerRulesViewModel(context: context)
        self.reportStatusViewModel = ReportStatusViewModel(context: context, user: user, status: status)
        self.reportSupplementaryViewModel = ReportSupplementaryViewModel(context: context, user: user)
        // end init
        
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        
        // setup reason viewModel
        if status != nil {
            reportReasonViewModel.headline = L10n.Scene.Report.StepOne.whatsWrongWithThisPost
        } else {
            Task { @MainActor in
                let managedObjectContext = context.managedObjectContext
                let _username: String? = try? await managedObjectContext.perform {
                    let user = user.object(in: managedObjectContext)
                    return user?.acctWithDomain
                }
                if let username = _username {
                    reportReasonViewModel.headline = L10n.Scene.Report.StepOne.whatsWrongWithThisUsername(username)
                } else {
                    reportReasonViewModel.headline = L10n.Scene.Report.StepOne.whatsWrongWithThisAccount
                }
            }   // end Task
        }
        
        // bind server rules
        Task { @MainActor in
            do {
                let response = try await context.apiService.instance(domain: authenticationBox.domain)
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
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value,
              !isReporting
        else {
            assertionFailure()
            return
        }

        let managedObjectContext = context.managedObjectContext
        let _query: Mastodon.API.Reports.FileReportQuery? = try await managedObjectContext.perform {
            guard let user = self.user.object(in: managedObjectContext) else { return nil }
            
            // the status picker is essential step in report flow
            // only check isSkip or not
            let statusIDs: [Status.ID]? = {
                if self.reportStatusViewModel.isSkip {
                    let _id: Status.ID? = self.reportStatusViewModel.status.flatMap { record -> Status.ID? in
                        guard let status = record.object(in: managedObjectContext) else { return nil }
                        return status.id
                    }
                    return _id.flatMap { [$0] }
                } else {
                    return self.reportStatusViewModel.selectStatuses.compactMap { record -> Status.ID? in
                        guard let status = record.object(in: managedObjectContext) else { return nil }
                        return status.id
                    }
                }
            }()
            
            // the user comment is essential step in report flow
            // only check isSkip or not
            let comment: String? = {
                var suffixes: [String] = []
                let content: String?
                
                // the server rules is NOT essential step in report flow
                // append suffix depends which reason
                if let reason = self.reportReasonViewModel.selectReason {
                    switch reason {
                    case .spam:
                        suffixes.append(reason.rawValue)
                    case .violateRule:
                        suffixes.append(reason.rawValue)
                        if let rule = self.reportServerRulesViewModel.selectRule {
                            suffixes.append(rule.text)
                        } else {
                            assertionFailure("should select valid rule")
                        }
                    case .dislike:
                        assertionFailure("should not enter the report flow")
                    case .other:
                        break
                    }
                }
                    
                content = self.reportSupplementaryViewModel.isSkip ? nil : self.reportSupplementaryViewModel.commentContext.comment
                
                let suffix: String? = {
                    let text = suffixes.joined(separator: ". ")
                    guard !text.isEmpty else { return nil }
                    return "<" + text + ">"
                }()
                
                let comment = [content, suffix]
                    .compactMap { $0 }
                    .joined(separator: " ")
                return comment.isEmpty ? nil : comment
            }()
            return Mastodon.API.Reports.FileReportQuery(
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
                        guard let rule = self.reportServerRulesViewModel.selectRule else { return nil }
                        return [rule.id]
                    default:
                        return nil
                    }
                }()
            )
        }

        guard let query = _query else { return }

        do {
            isReporting = true
            #if DEBUG
            try await Task.sleep(nanoseconds: .second * 3)
            #else
            let _ = try await context.apiService.report(
                query: query,
                authenticationBox: authenticationBox
            )
            #endif
            isReportSuccess = true
        } catch {
            isReporting = false
            throw error
        }
    }
}
