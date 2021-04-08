//
//  FavoriteViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-7.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension FavoriteViewModel {
    class State: GKState {
        weak var viewModel: FavoriteViewModel?
        
        init(viewModel: FavoriteViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension FavoriteViewModel.State {
    class Initial: FavoriteViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return viewModel.activeMastodonAuthenticationBox.value != nil
            default:
                return false
            }
        }
    }
    
    class Reloading: FavoriteViewModel.State {
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
            viewModel.statusFetchedResultsController.statusIDs.value = []
            
            stateMachine.enter(Loading.self)
        }
    }
    
    class Fail: FavoriteViewModel.State {
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
    
    class Idle: FavoriteViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: FavoriteViewModel.State {
        
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
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let activeMastodonAuthenticationBox = viewModel.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            if previousState is Reloading {
                maxID = nil
            }
            // prefer use `maxID` token in response header
            // let maxID = viewModel.statusFetchedResultsController.statusIDs.value.last
            
            viewModel.context.apiService.favoritedStatuses(
                maxID: maxID,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox
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

                var hasNewStatusesAppend = false
                var statusIDs = viewModel.statusFetchedResultsController.statusIDs.value
                for status in response.value {
                    guard !statusIDs.contains(status.id) else { continue }
                    statusIDs.append(status.id)
                    hasNewStatusesAppend = true
                }
                
                self.maxID = response.link?.maxID
                
                let hasNextPage: Bool = {
                    guard let link = response.link else { return true }     // assert has more when link invalid
                    return link.maxID != nil
                }()

                if hasNewStatusesAppend && hasNextPage {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                viewModel.statusFetchedResultsController.statusIDs.value = statusIDs
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class NoMore: FavoriteViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
}
