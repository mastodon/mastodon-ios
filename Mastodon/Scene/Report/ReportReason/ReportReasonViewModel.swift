//
//  ReportReasonViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import UIKit
import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonSDK
import MastodonLocalization

final class ReportReasonViewModel: ObservableObject {
    
    weak var delegate: ReportReasonViewControllerDelegate?
    
    // input
    let context: AppContext
    
    @Published var headline = L10n.Scene.Report.StepOne.whatsWrongWithThisAccount
    @Published var serverRules: [Mastodon.Entity.Instance.Rule]?

    @Published var bottomPaddingHeight: CGFloat = .zero
    @Published var backgroundColor: UIColor = Asset.Scene.Report.background.color
    
    // output
    @Published var selectReason: Reason?
    
    init(context: AppContext) {
        self.context = context
        // end init
    }
    
}

extension ReportReasonViewModel {
    enum Reason: Hashable, CaseIterable {
        case dislike
        case spam
        case violateRule
        case other
        
        var title: String {
            switch self {
            case .dislike:
                return L10n.Scene.Report.StepOne.iDontLikeIt
            case .spam:
                return L10n.Scene.Report.StepOne.itsSpam
            case .violateRule:
                return L10n.Scene.Report.StepOne.itViolatesServerRules
            case .other:
                return L10n.Scene.Report.StepOne.itsSomethingElse
            }
        }
        
        var subtitle: String {
            switch self {
            case .dislike:
                return L10n.Scene.Report.StepOne.itIsNotSomethingYouWantToSee
            case .spam:
                return L10n.Scene.Report.StepOne.maliciousLinksFakeEngagementOrRepetetiveReplies
            case .violateRule:
                return L10n.Scene.Report.StepOne.youAreAwareThatItBreaksSpecificRules
            case .other:
                return L10n.Scene.Report.StepOne.theIssueDoesNotFitIntoOtherCategories
            }
        }
        
        // do not i18n this
        var rawValue: String {
            switch self {
            case .dislike:
                return "I don’t like it"
            case .spam:
                return "It’s spam"
            case .violateRule:
                return "It violates server rules"
            case .other:
                return "It’s something else"
            }
        }
    }
}
