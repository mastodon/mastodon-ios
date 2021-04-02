//
//  UserTimelineViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension UserTimelineViewModel {
    class State: GKState {
        weak var viewModel: UserTimelineViewModel?
        
        init(viewModel: UserTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension UserTimelineViewModel.State {
    class Initial: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return viewModel.userID.value != nil
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            case is NoMore.Type:
                return true
            case is NotAuthorized.Type, is Blocked.Type:
                return true
            case is Suspended.Type:
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
            
            guard let userID = viewModel.userID.value, !userID.isEmpty else {
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            let domain = activeMastodonAuthenticationBox.domain
            let queryFilter = viewModel.queryFilter.value
            
            viewModel.context.apiService.userTimeline(
                domain: domain,
                accountID: userID,
                maxID: nil,
                sinceID: nil,
                excludeReplies: queryFilter.excludeReplies,
                excludeReblogs: queryFilter.excludeReblogs,
                onlyMedia: queryFilter.onlyMedia,
                authorizationBox: activeMastodonAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { response in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
                
                var hasNewStatusesAppend = false
                var statusIDs = viewModel.statusFetchedResultsController.statusIDs.value
                for status in response.value {
                    guard !statusIDs.contains(status.id) else { continue }
                    statusIDs.append(status.id)
                    hasNewStatusesAppend = true
                }
                
                if hasNewStatusesAppend {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                viewModel.statusFetchedResultsController.statusIDs.value = statusIDs
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is LoadingMore.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Idle: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is LoadingMore.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class LoadingMore: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            case is NoMore.Type:
                return true
            case is NotAuthorized.Type, is Blocked.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let maxID = viewModel.statusFetchedResultsController.statusIDs.value.last else {
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let userID = viewModel.userID.value, !userID.isEmpty else {
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            let domain = activeMastodonAuthenticationBox.domain
            let queryFilter = viewModel.queryFilter.value
            
            viewModel.context.apiService.userTimeline(
                domain: domain,
                accountID: userID,
                maxID: maxID,
                sinceID: nil,
                excludeReplies: queryFilter.excludeReplies,
                excludeReblogs: queryFilter.excludeReblogs,
                onlyMedia: queryFilter.onlyMedia,
                authorizationBox: activeMastodonAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { response in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
                
                var hasNewStatusesAppend = false
                var statusIDs = viewModel.statusFetchedResultsController.statusIDs.value
                for status in response.value {
                    guard !statusIDs.contains(status.id) else { continue }
                    statusIDs.append(status.id)
                    hasNewStatusesAppend = true
                }
                
                if hasNewStatusesAppend {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                viewModel.statusFetchedResultsController.statusIDs.value = statusIDs
            }
            .store(in: &viewModel.disposeBag)
        }
    }
        
    class NotAuthorized: UserTimelineViewModel.State {
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }

    }
    
    class Blocked: UserTimelineViewModel.State {
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
    }
    
    class Suspended: UserTimelineViewModel.State {

    }
    
    class NoMore: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is NotAuthorized.Type, is Blocked.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
    }
}
