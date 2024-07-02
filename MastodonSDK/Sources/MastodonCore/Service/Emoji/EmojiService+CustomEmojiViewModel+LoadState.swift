//
//  EmojiService+CustomEmojiViewModel+LoadState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import Foundation
import GameplayKit

extension EmojiService.CustomEmojiViewModel {
    class LoadState: GKState {
        weak var viewModel: EmojiService.CustomEmojiViewModel?
        
        init(viewModel: EmojiService.CustomEmojiViewModel) {
            self.viewModel = viewModel
        }
    }
}

extension EmojiService.CustomEmojiViewModel.LoadState {
    
    class Initial: EmojiService.CustomEmojiViewModel.LoadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: EmojiService.CustomEmojiViewModel.LoadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Finish.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel,
                  let authenticationBox = viewModel.service.authenticationService.mastodonAuthenticationBoxes.first,
                  let stateMachine else { return }

            let apiService = viewModel.service.apiService

            apiService.customEmoji(domain: viewModel.domain, authenticationBox: authenticationBox)
                // .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(_):
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    stateMachine.enter(Finish.self)
                    viewModel.emojis.value = response.value
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: EmojiService.CustomEmojiViewModel.LoadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Finish.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let stateMachine = stateMachine else { return }
            
            // retry 10s later
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Finish: EmojiService.CustomEmojiViewModel.LoadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // one time task
            return false
        }
    }

}
