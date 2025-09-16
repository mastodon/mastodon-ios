//
//  ComposeViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonMeta
import MastodonUI
import SwiftUI

final class ComposeViewModel {

    enum Context {
        case composeStatus(quoting: (Mastodon.Entity.Status, ()->AnyView)?)
        case editStatus(status: MastodonStatus, statusSource: Mastodon.Entity.StatusSource, quoting: (()->AnyView)?)
    }
    
    var disposeBag = Set<AnyCancellable>()

    let id = UUID()
    
    // input
    let authenticationBox: MastodonAuthenticationBox
    let composeContext: Context
    let destination: ComposeContentViewModel.Destination
    let initialContent: String

    let traitCollectionDidChangePublisher = CurrentValueSubject<Void, Never>(Void())      // use CurrentValueSubject to make initial event emit
    
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
        }
        
        self.title = title
        
        self.postPublishCompletion = completion
    }
}
