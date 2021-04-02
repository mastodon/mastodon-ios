//
//  PublicTimelineViewModel+State.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/2.
//

import Foundation
import GameplayKit
import MastodonSDK
import os.log

extension PublicTimelineViewModel {
    class State: GKState {
        weak var viewModel: PublicTimelineViewModel?
        
        init(viewModel: PublicTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", (#file as NSString).lastPathComponent, #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension PublicTimelineViewModel.State {
    class Initial: PublicTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: PublicTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }

            viewModel.context.apiService.publicTimeline(domain: activeMastodonAuthenticationBox.domain)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch user timeline latest response error: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                        
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    let resposeStatusIDs = response.value.compactMap { $0.id }
                    var newStatusIDs = resposeStatusIDs
                    let oldStatusIDs = viewModel.statusIDs.value
                    var hasGap = true
                    for statusID in oldStatusIDs {
                        if !newStatusIDs.contains(statusID) {
                            newStatusIDs.append(statusID)
                        } else {
                            hasGap = false
                        }
                    }
                    if hasGap && oldStatusIDs.count > 0 {
                        resposeStatusIDs.last.flatMap { viewModel.statusIDsWhichHasGap.append($0) }
                    }
                    viewModel.statusIDs.value = newStatusIDs
                    stateMachine.enter(Idle.self)
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: PublicTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type, is LoadingMore.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }

            // trigger items update
            viewModel.items.value = viewModel.items.value
        }
    }
    
    class Idle: PublicTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type, is LoadingMore.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class LoadingMore: PublicTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            let maxID = viewModel.statusIDs.value.last
            viewModel.context.apiService.publicTimeline(
                domain: activeMastodonAuthenticationBox.domain,
                maxID: maxID
            )
            .sink { completion in
                switch completion {
                case .failure(let error):
                    stateMachine.enter(Fail.self)
                    os_log("%{public}s[%{public}ld], %{public}s: load more fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { response in
                stateMachine.enter(Idle.self)
                var oldStatusIDs = viewModel.statusIDs.value
                for status in response.value {
                    if !oldStatusIDs.contains(status.id) {
                        oldStatusIDs.append(status.id)
                    }
                }
                
                viewModel.statusIDs.value = oldStatusIDs
            }
            .store(in: &viewModel.disposeBag)
        }
    }
}
