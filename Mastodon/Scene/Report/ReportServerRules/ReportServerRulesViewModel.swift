//
//  ReportServerRulesViewModel.swift
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

final class ReportServerRulesViewModel: ObservableObject {
    
    weak var delegate: ReportServerRulesViewControllerDelegate?
    
    // input
    let context: AppContext

    @Published var headline = L10n.Scene.Report.StepTwo.whichRulesAreBeingViolated
    @Published var serverRules: [Mastodon.Entity.Instance.Rule] = []

    @Published var bottomPaddingHeight: CGFloat = .zero
    @Published var backgroundColor: UIColor = Asset.Scene.Report.background.color
    
    // output
    @Published var selectRules: Set<Mastodon.Entity.Instance.Rule> = Set()
    
    init(context: AppContext) {
        self.context = context
        // end init
    }
    
}
