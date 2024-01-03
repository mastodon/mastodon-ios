//
//  BookmarkViewModel+State.swift
//  Mastodon
//
//  Created by ProtoLimit on 2022-07-19.
//

import Foundation
import GameplayKit
import MastodonSDK
import MastodonCore

extension BookmarkViewModel {
    class State: GKState {
        
        let id = UUID()

        weak var viewModel: BookmarkViewModel?
        
        init(viewModel: BookmarkViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
        
    }
}

extension BookmarkViewModel.State {
    class Initial: BookmarkViewModel.State {
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
    
    class Reloading: BookmarkViewModel.State {
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
            DispatchQueue.main.async {
                viewModel.dataController.reset()
            }
            
            stateMachine.enter(Loading.self)
        }
    }
    
    class Fail: BookmarkViewModel.State {
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
    
    class Idle: BookmarkViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: BookmarkViewModel.State {
        
        // prefer use `maxID` token in response header
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
            guard let viewModel = viewModel, let _ = stateMachine else { return }
            
            if previousState is Reloading {
                maxID = nil
            }
            
            Task {
                do {
                    let response = try await viewModel.context.apiService.bookmarkedStatuses(
                        maxID: maxID,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    var hasNewStatusesAppend = false
                    var statusIDs = await viewModel.dataController.records.map { $0.entity }
                    for status in response.value {
                        guard !statusIDs.contains(status) else { continue }
                        statusIDs.append(status)
                        hasNewStatusesAppend = true
                    }
                    
                    self.maxID = response.link?.maxID
                    
                    let hasNextPage: Bool = {
                        guard let link = response.link else { return true }     // assert has more when link invalid
                        return link.maxID != nil
                    }()

                    if hasNewStatusesAppend && hasNextPage {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }

                    await viewModel.dataController.setRecords(statusIDs.map { MastodonStatus.fromEntity($0) })

                } catch {
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }
    
    class NoMore: BookmarkViewModel.State {
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
