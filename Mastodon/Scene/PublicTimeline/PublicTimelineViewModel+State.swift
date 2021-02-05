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
                    viewModel.isFetchingLatestTimeline.value = false
                    let resposeTootIDs = response.value.compactMap { $0.id }
                    var newTootsIDs = resposeTootIDs
                    let oldTootsIDs = viewModel.tootIDs.value
                    var hasGap = true
                    for tootID in oldTootsIDs {
                        if !newTootsIDs.contains(tootID) {
                            newTootsIDs.append(tootID)
                        } else {
                            hasGap = false
                        }
                    }
                    if hasGap && oldTootsIDs.count > 0 {
                        resposeTootIDs.last.flatMap { viewModel.tootIDsWhichHasGap.append($0) }
                    }
                    viewModel.tootIDs.value = newTootsIDs
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
            let maxID = viewModel.tootIDs.value.last
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
                var oldTootsIDs = viewModel.tootIDs.value
                for toot in response.value {
                    if !oldTootsIDs.contains(toot.id) {
                        oldTootsIDs.append(toot.id)
                    }
                }
                
                viewModel.tootIDs.value = oldTootsIDs
            }
            .store(in: &viewModel.disposeBag)
        }
    }
}
