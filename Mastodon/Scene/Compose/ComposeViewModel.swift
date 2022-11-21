//
//  ComposeViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
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
    
    let logger = Logger(subsystem: "ComposeViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()

    let id = UUID()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let kind: ComposeContentViewModel.Kind

    let traitCollectionDidChangePublisher = CurrentValueSubject<Void, Never>(Void())      // use CurrentValueSubject to make initial event emit
    
    // output
    
    // UI & UX
    @Published var title: String
    
    init(
        context: AppContext,
        authContext: AuthContext,
        kind: ComposeContentViewModel.Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        // end init
        
        self.title = {
            switch kind {
            case .post, .hashtag, .mention:       return L10n.Scene.Compose.Title.newPost
            case .reply:                          return L10n.Scene.Compose.Title.newReply
            }
        }()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
