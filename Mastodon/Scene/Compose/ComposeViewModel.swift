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

final class ComposeViewModel {

    enum Context {
        case composeStatus
        case editStatus(status: Status, statusSource: Mastodon.Entity.StatusSource)
    }
    
    var disposeBag = Set<AnyCancellable>()

    let id = UUID()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let composeContext: Context
    let destination: ComposeContentViewModel.Destination
    let initialContent: String

    let traitCollectionDidChangePublisher = CurrentValueSubject<Void, Never>(Void())      // use CurrentValueSubject to make initial event emit
    
    // output
    
    // UI & UX
    @Published var title: String
    
    init(
        context: AppContext,
        authContext: AuthContext,
        composeContext: ComposeViewModel.Context,
        destination: ComposeContentViewModel.Destination,
        initialContent: String = ""
    ) {
        self.context = context
        self.authContext = authContext
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
        case .editStatus(_, _):
            title = L10n.Scene.Compose.Title.editPost
        }
        
        self.title = title
    }
}
