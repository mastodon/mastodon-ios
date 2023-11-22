//
//  UserTimelineViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import Foundation
import GameplayKit
import MastodonCore
import MastodonSDK

extension UserTimelineViewModel {
    class State: GKState {
        let id = UUID()

        weak var viewModel: UserTimelineViewModel?
        
        init(viewModel: UserTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
        
    }
}

extension UserTimelineViewModel.State {
    class Initial: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return viewModel.userIdentifier != nil
            default:
                return false
            }
        }
    }
    
    class Reloading: UserTimelineViewModel.State {
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

            Task {
                // reset
                await viewModel.statusFetchedResultsController.reset()

                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Fail: UserTimelineViewModel.State {
        
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
    
    class Idle: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: UserTimelineViewModel.State {
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
            

            Task {
                let maxID = await viewModel.statusFetchedResultsController.records.last?.id
                
                guard let userID = viewModel.userIdentifier?.userID, !userID.isEmpty else {
                    stateMachine.enter(Fail.self)
                    return
                }
                
                let queryFilter = viewModel.queryFilter

                do {
                    let response = try await viewModel.context.apiService.userTimeline(
                        accountID: userID,
                        maxID: maxID,
                        sinceID: nil,
                        excludeReplies: queryFilter.excludeReplies,
                        excludeReblogs: queryFilter.excludeReblogs,
                        onlyMedia: queryFilter.onlyMedia,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    var hasNewStatusesAppend = false
                    var statusIDs = await viewModel.statusFetchedResultsController.records
                    for status in response.value {
                        guard !statusIDs.contains(where: { $0.id == status.id }) else { continue }
                        statusIDs.append(.fromEntity(status))
                        hasNewStatusesAppend = true
                    }
                    
                    if hasNewStatusesAppend {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    await viewModel.statusFetchedResultsController.setRecords(statusIDs)
                    
                } catch {
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }
    
    class NoMore: UserTimelineViewModel.State {
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
            guard let viewModel = viewModel, let _ = stateMachine else { return }
            
            // trigger data source update. otherwise, spinner always display
            viewModel.isSuspended = viewModel.isSuspended

            // remove bottom loader
            guard let diffableDataSource = viewModel.diffableDataSource else { return }
            var snapshot = diffableDataSource.snapshot()
            snapshot.deleteItems([.bottomLoader])
            diffableDataSource.apply(snapshot)
        }
    }
}
