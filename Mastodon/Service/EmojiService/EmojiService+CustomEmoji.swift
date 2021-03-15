//
//  EmojiService+CustomEmoji.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import Foundation
import Combine
import GameplayKit
import MastodonSDK

extension EmojiService {
    final class CustomEmoji {
        
        var disposeBag = Set<AnyCancellable>()
        
        // input
        let domain: String
        let context: AppContext
        
        // output
        private(set) lazy var stateMachine: GKStateMachine = {
            // exclude timeline middle fetcher state
            let stateMachine = GKStateMachine(states: [
                LoadState.Initial(viewModel: self),
                LoadState.Loading(viewModel: self),
                LoadState.Fail(viewModel: self),
                LoadState.Finish(viewModel: self),
            ])
            stateMachine.enter(LoadState.Initial.self)
            return stateMachine
        }()
        let emojis = CurrentValueSubject<[Mastodon.Entity.Emoji], Never>([])
        
        init(domain: String, context: AppContext) {
            self.domain = domain
            self.context = context
            
            // trigger loading
            stateMachine.enter(LoadState.Loading.self)
        }
        
    }
}
