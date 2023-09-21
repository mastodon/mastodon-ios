//
//  FollowerListViewModel+State.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import Foundation
import GameplayKit
import MastodonSDK
import MastodonCore
import CoreDataStack

extension FollowerListViewModel {
    class State: GKState {
        
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        
        weak var viewModel: FollowerListViewModel?
        
        init(viewModel: FollowerListViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            let from = previousState.flatMap { String(describing: $0) } ?? "nil"
            let to = String(describing: self)
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension FollowerListViewModel.State {
    class Initial: FollowerListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return viewModel.userID != nil
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
            viewModel.userFetchedResultsController.userIDs = []
            
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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

            guard let userID = viewModel.userID, !userID.isEmpty else {
                stateMachine.enter(Fail.self)
                return
            }
            
            Task {
                do {
                    let response = try await viewModel.context.apiService.followers(
                        userID: userID,
                        maxID: maxID,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    var hasNewAppend = false
                    var userIDs = viewModel.userFetchedResultsController.userIDs
                    for user in response.value {
                        guard !userIDs.contains(user.id) else { continue }
                        userIDs.append(user.id)
                        hasNewAppend = true
                    }
                    
                    let maxID = response.link?.maxID
                    
                    if hasNewAppend && maxID != nil {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    
                    self.maxID = maxID
                    viewModel.userFetchedResultsController.userIDs = userIDs
                    
                } catch {
                    await enter(state: Fail.self)
                }
            }   // end Task
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
