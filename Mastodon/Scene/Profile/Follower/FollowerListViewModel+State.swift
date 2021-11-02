//
//  FollowerListViewModel+State.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension FollowerListViewModel {
    class State: GKState {
        weak var viewModel: FollowerListViewModel?
        
        init(viewModel: FollowerListViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension FollowerListViewModel.State {
    class Initial: FollowerListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return viewModel.userID.value != nil
            default:
                return false
            }
        }
    }
    
    class Reloading: FollowerListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            // reset
            viewModel.userFetchedResultsController.userIDs.value = []
            
            stateMachine.enter(Loading.self)
        }
    }
    
    class Fail: FollowerListViewModel.State {
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let _ = viewModel, let stateMachine = stateMachine else { return }
            
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading 3s later…", ((#file as NSString).lastPathComponent), #line, #function)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading", ((#file as NSString).lastPathComponent), #line, #function)
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Idle: FollowerListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: FollowerListViewModel.State {
        
        var maxID: String?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            case is NoMore.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            if previousState is Reloading {
                maxID = nil
            }
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }

            guard let userID = viewModel.userID.value, !userID.isEmpty else {
                stateMachine.enter(Fail.self)
                return
            }

            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }

            viewModel.context.apiService.followers(
                userID: userID,
                maxID: maxID,
                authorizationBox: activeMastodonAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch user timeline fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    stateMachine.enter(Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { response in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

                var hasNewAppend = false
                var userIDs = viewModel.userFetchedResultsController.userIDs.value
                for user in response.value {
                    guard !userIDs.contains(user.id) else { continue }
                    userIDs.append(user.id)
                    hasNewAppend = true
                }
                
                let maxID = response.link?.maxID
                
                if maxID != nil {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                self.maxID = maxID
                viewModel.userFetchedResultsController.userIDs.value = userIDs
            }
            .store(in: &viewModel.disposeBag)
        }   // end func didEnter
    }
    
    class NoMore: FollowerListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
        }
    }
}
