//
//  UserListViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import Foundation
import GameplayKit
import MastodonSDK

extension UserListViewModel {
    class State: GKState {

        let id = UUID()
        
        weak var viewModel: UserListViewModel?
        
        init(viewModel: UserListViewModel) {
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

extension UserListViewModel.State {
    class Initial: UserListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let _ = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: UserListViewModel.State {
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
    
    class Fail: UserListViewModel.State {
        
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
    
    class Idle: UserListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: UserListViewModel.State {
        
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
            
            guard let viewModel = viewModel else { return }
            
            let maxID = self.maxID
            
            Task {
                do {
                    let response: Mastodon.Response.Content<[Mastodon.Entity.Account]>
                    switch viewModel.kind {
                    case .favoritedBy(let status):
                        response = try await viewModel.context.apiService.favoritedBy(
                            status: status,
                            query: .init(maxID: maxID, limit: nil),
                            authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                        )
                    case .rebloggedBy(let status):
                        response = try await viewModel.context.apiService.rebloggedBy(
                            status: status,
                            query: .init(maxID: maxID, limit: nil),
                            authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                        )
                    }

                    var hasNewAppend = false
                    var userIDs = viewModel.userFetchedResultsController.userIDs
                    for user in response.value {
                        guard !userIDs.contains(user.id) else { continue }
                        userIDs.append(user.id)
                        hasNewAppend = true
                    }
                                        
                    let maxID = response.link?.maxID
                    
                    if hasNewAppend, maxID != nil {
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
    
    class NoMore: UserListViewModel.State {
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
            
            guard let viewModel = viewModel else { return }
            // trigger reload
            viewModel.userFetchedResultsController.userIDs = viewModel.userFetchedResultsController.userIDs
        }
    }
}
