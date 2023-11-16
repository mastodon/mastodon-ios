//
//  ReportResultViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-8.
//

import Combine
import Foundation
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

class ReportResultViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let user: Mastodon.Entity.Account
    let isReported: Bool
    
    var headline: String {
        isReported ? L10n.Scene.Report.reportSentTitle : L10n.Scene.Report.StepFinal.dontWantToSeeThis
    }
    @Published var bottomPaddingHeight: CGFloat = .zero
    @Published var backgroundColor: UIColor = Asset.Scene.Report.background.color
    
    @Published var isRequestFollow = false
    @Published var isRequestMute = false
    @Published var isRequestBlock = false
    
    // output
    @Published var avatarURL: URL?
    @Published var username: String = ""
    
    let relationshipViewModel = RelationshipViewModel()
    let muteActionPublisher = PassthroughSubject<Void, Never>()
    let followActionPublisher = PassthroughSubject<Void, Never>()
    let blockActionPublisher = PassthroughSubject<Void, Never>()
    
    init(
        context: AppContext,
        authContext: AuthContext,
        user: Mastodon.Entity.Account,
        isReported: Bool
    ) {
        self.context = context
        self.authContext = authContext
        self.user = user
        self.isReported = isReported
        // end init
        
        Task { @MainActor in
            self.relationshipViewModel.user = user
            self.relationshipViewModel.me = authContext.mastodonAuthenticationBox.inMemoryCache.meAccount
            
            self.avatarURL = user.avatarImageURL()
            self.username = user.acctWithDomain
            
        }   // end Task
    }

}


