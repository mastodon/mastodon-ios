//
//  ReportReasonViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import UIKit
import SwiftUI
import MastodonAsset
import MastodonSDK

final class ReportReasonViewModel: ObservableObject {
    
    weak var delegate: ReportReasonViewControllerDelegate?
    
    // input
    let context: AppContext
    
    @Published var headline = "What's wrong with this account?"
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
                return "I don’t like it"
            case .spam:
                return "It’s spam"
            case .violateRule:
                return "It violates server rules"
            case .other:
                return "It’s something else"
            }
        }
        
        var subtitle: String {
            switch self {
            case .dislike:
                return "It is not something you want to see"
            case .spam:
                return "Malicious links, fake engagement, or repetetive replies"
            case .violateRule:
                return "You are aware that it breaks specific rules"
            case .other:
                return "The issue does not fit into other categories"
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
