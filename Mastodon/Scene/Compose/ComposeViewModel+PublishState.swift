//
//  ComposeViewModel+PublishState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK

extension ComposeViewModel {
    class PublishState: GKState {
        weak var viewModel: ComposeViewModel?
        
        init(viewModel: ComposeViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension ComposeViewModel.PublishState {
    class Initial: ComposeViewModel.PublishState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Publishing.self
        }
    }
    
    class Publishing: ComposeViewModel.PublishState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Finish.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let mastodonAuthenticationBox = viewModel.activeAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let query = Mastodon.API.Statuses.PublishStatusQuery(
                status: viewModel.composeStatusAttribute.composeContent.value,
                mediaIDs: nil
            )
            viewModel.context.apiService.publishStatus(
                domain: mastodonAuthenticationBox.domain,
                query: query,
                mastodonAuthenticationBox: mastodonAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: publish status %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    stateMachine.enter(Fail.self)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: publish status success", ((#file as NSString).lastPathComponent), #line, #function)
                    stateMachine.enter(Finish.self)
                }
            } receiveValue: { status in
                
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: ComposeViewModel.PublishState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // allow discard publishing
            return stateClass == Publishing.self || stateClass == Finish.self
        }
    }
    
    class Finish: ComposeViewModel.PublishState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }

}
