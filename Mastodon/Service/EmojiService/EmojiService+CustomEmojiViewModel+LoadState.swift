//
//  EmojiService+CustomEmojiViewModel+LoadState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import os.log
import Foundation
import GameplayKit

extension EmojiService.CustomEmojiViewModel {
    class LoadState: GKState {
        weak var viewModel: EmojiService.CustomEmojiViewModel?
        
        init(viewModel: EmojiService.CustomEmojiViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
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
            guard let viewModel = viewModel, let apiService = viewModel.service?.apiService, let stateMachine = stateMachine else { return }
            
            apiService.customEmoji(domain: viewModel.domain)
                // .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: failed to load custom emojis for %s: %s. Retry 10s later", ((#file as NSString).lastPathComponent), #line, #function, viewModel.domain, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: load %ld custom emojis for %s", ((#file as NSString).lastPathComponent), #line, #function, response.value.count, viewModel.domain)
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
