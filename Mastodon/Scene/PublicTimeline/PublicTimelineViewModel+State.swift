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

            viewModel.fetchLatest()
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
                    let tootsIDs = response.value.map { $0.id }
                    viewModel.tootIDs.value = tootsIDs
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
        
            viewModel.loadMore()
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
