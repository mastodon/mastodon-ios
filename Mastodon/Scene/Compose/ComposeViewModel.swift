//
//  ComposeViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import MastodonSDK
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI
import SwiftUI

final class ComposeViewModel {

    enum Context {
        case composeStatus(quoting: (Mastodon.Entity.Status, ()->AnyView)?)
        case editStatus(status: MastodonStatus, statusSource: Mastodon.Entity.StatusSource, quoting: (()->AnyView)?)
        case mentioning(account: Mastodon.Entity.Account, privately: Bool)
    }

    let id = UUID()
    
    // input
    let authenticationBox: MastodonAuthenticationBox
    let composeContext: Context
    let destination: ComposeContentViewModel.Destination
    let initialContent: String

    // output
    let postPublishCompletion: ((Bool)->())?
    
    // UI & UX
    @Published var title: String
    
    init(
        authenticationBox: MastodonAuthenticationBox,
        composeContext: ComposeViewModel.Context,
        destination: ComposeContentViewModel.Destination,
        initialContent: String = "",
        completion: ((Bool)->())? = nil
    ) {
        self.authenticationBox = authenticationBox
        self.destination = destination
        self.initialContent = initialContent
        self.composeContext = composeContext
        // end init
        
        let title: String
        
        switch composeContext {
        case .composeStatus:
            switch destination {
            case .topLevel:
                title = L10n.Scene.Compose.Title.newPost
            case .reply:
                title = L10n.Scene.Compose.Title.newReply
            }
        case .editStatus:
            title = L10n.Scene.Compose.Title.editPost
        case .mentioning:
            title = L10n.Scene.Compose.Title.newPost
        }
        
        self.title = title
        
        self.postPublishCompletion = completion
    }
}
