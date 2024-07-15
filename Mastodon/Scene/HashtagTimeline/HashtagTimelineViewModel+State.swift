//
//  HashtagTimelineViewModel+State.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/31.
//

import Foundation
import GameplayKit
import CoreDataStack
import MastodonSDK

extension HashtagTimelineViewModel {
    class State: GKState {
        
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }

        weak var viewModel: HashtagTimelineViewModel?
        
        init(viewModel: HashtagTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension HashtagTimelineViewModel.State {
    class Initial: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: HashtagTimelineViewModel.State {
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
            guard let stateMachine = stateMachine else { return }

            stateMachine.enter(Loading.self)
        }
    }
    
    class Fail: HashtagTimelineViewModel.State {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Idle: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: HashtagTimelineViewModel.State {
        var maxID: Status.ID?
        
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
            guard let viewModel else { return }
            
            switch previousState {
            case is Reloading:
                maxID = nil
            default:
                break
            }
            
            // TODO: only set large count when using Wi-Fi
            let maxID = self.maxID
            let isReloading = maxID == nil

            Task {
                do {
                    let response = try await viewModel.context.apiService.hashtagTimeline(
                        maxID: maxID,
                        hashtag: viewModel.hashtag,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                                        
                    let newMaxID: String? = {
                        guard let maxID = response.link?.maxID else { return nil }
                        return maxID
                    }()
                    
                    let hasMore: Bool = {
                        guard let newMaxID = newMaxID else { return false }
                        return newMaxID != maxID
                    }()
                    
                    self.maxID = newMaxID
                    
                    var hasNewStatusesAppend = false
                    var statusIDs = isReloading ? [] : await viewModel.dataController.records.map { $0.entity }
                    for status in response.value {
                        guard !statusIDs.contains(status) else { continue }
                        statusIDs.append(status)
                        hasNewStatusesAppend = true
                    }

                    if hasNewStatusesAppend, hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    
                    await viewModel.dataController.setRecords(statusIDs.map { MastodonStatus.fromEntity($0) })
                    viewModel.didLoadLatest.send()
                } catch {
                    await enter(state: Fail.self)
                }
            }   // end Task
        }
    }

    class NoMore: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            guard let viewModel = viewModel else { return }
            guard let diffableDataSource = viewModel.diffableDataSource else {
                assertionFailure()
                return
            }
            DispatchQueue.main.async {
                var snapshot = diffableDataSource.snapshot()
                snapshot.deleteItems([.bottomLoader])
                diffableDataSource.apply(snapshot)
            }
        }
    }
}

