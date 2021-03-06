//
//  MastodonPickServerViewModel+LoadIndexedServerState.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension MastodonPickServerViewModel {
    class LoadIndexedServerState: GKState {
        weak var viewModel: MastodonPickServerViewModel?
        
        init(viewModel: MastodonPickServerViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension MastodonPickServerViewModel.LoadIndexedServerState {

    class Initial: MastodonPickServerViewModel.LoadIndexedServerState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: MastodonPickServerViewModel.LoadIndexedServerState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = self.viewModel, let stateMachine = self.stateMachine else { return }
            viewModel.isLoadingIndexedServers.value = true
            viewModel.context.apiService.servers(language: nil, category: nil)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        // TODO: handle error
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { [weak self] response in
                    guard let _ = self else { return }
                    stateMachine.enter(Idle.self)
                    viewModel.indexedServers.value = response.value
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: MastodonPickServerViewModel.LoadIndexedServerState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let stateMachine = self.stateMachine else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let _ = self else { return }
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Idle: MastodonPickServerViewModel.LoadIndexedServerState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = self.viewModel, let stateMachine = self.stateMachine else { return }
            viewModel.isLoadingIndexedServers.value = false
        }
    }

}
