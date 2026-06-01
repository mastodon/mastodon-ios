//
//  ReportSupplementaryViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import Combine
import MastodonCore
import MastodonSDK

class ReportSupplementaryViewModel {
    
    weak var delegate: ReportSupplementaryViewControllerDelegate?

    // Input
    let context: AppContext
    let authenticationBox: MastodonAuthenticationBox
    let account: Mastodon.Entity.Account
    let commentContext = ReportItem.CommentContext()
    
    @Published var isSkip = false
    @Published var isBusy = false
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ReportSection, ReportItem>?
    @Published var isNextButtonEnabled = false
    
    init(
        context: AppContext,
        authenticationBox: MastodonAuthenticationBox,
        account: Mastodon.Entity.Account
    ) {
        self.context = context
        self.authenticationBox = authenticationBox
        self.account = account
        // end init
        
        Publishers.CombineLatest(
            commentContext.$comment,
            $isBusy
        )
        .map { comment, isBusy -> Bool in
            guard !isBusy else { return false }
            return !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .assign(to: &$isNextButtonEnabled)
    }
    
}
