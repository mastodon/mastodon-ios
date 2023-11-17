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
            viewModel.records = []
            viewModel.accounts = []
            viewModel.relationships = []

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

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            viewModel?.tableView?.refreshControl?.endRefreshing()
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
            
            guard let viewModel, let stateMachine else { return }

            guard let userID = viewModel.userID, userID.isEmpty == false else {
                stateMachine.enter(Fail.self)
                return
            }

            Task {
                do {
                    let accountResponse = try await viewModel.context.apiService.followers(
                        userID: userID,
                        maxID: maxID,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )

                    if accountResponse.value.isEmpty {
                        await enter(state: NoMore.self)

                        viewModel.accounts = []
                        viewModel.relationships = []
                        return
                    }

                    var hasNewAppend = false

                    let newRelationships = try await viewModel.context.apiService.relationship(forAccounts: accountResponse.value, authenticationBox: viewModel.authContext.mastodonAuthenticationBox)


                    var newRecords = viewModel.records
                    var accounts = viewModel.accounts

                    for user in accountResponse.value {
                        guard accounts.contains(user) == false else { continue }
                        accounts.append(user)

                        hasNewAppend = true
                    }

                    var relationships = viewModel.relationships

                    for relationship in newRelationships.value {
                        guard relationships.contains(relationship) == false else { continue }
                        relationships.append(relationship)
                    }

                    let maxID = accountResponse.link?.maxID

                    if hasNewAppend, maxID != nil {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }

                    viewModel.accounts = accounts
                    viewModel.relationships = relationships
                    self.maxID = maxID
                    viewModel.records = newRecords

                } catch {
                    await enter(state: Fail.self)
                }
            }
        }
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

            viewModel?.tableView?.refreshControl?.endRefreshing()
        }
    }
}
