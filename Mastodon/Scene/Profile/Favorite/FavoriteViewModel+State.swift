//
//  FavoriteViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-7.
//

import os.log
import Foundation
import GameplayKit
import MastodonCore
import MastodonSDK

extension FavoriteViewModel {
    class State: GKState {
        
        let logger = Logger(subsystem: "FavoriteViewModel.State", category: "StateMachine")
        
        let id = UUID()
        
        weak var viewModel: FavoriteViewModel?
        
        init(viewModel: FavoriteViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            let from = previousState.flatMap { String(describing: $0) } ?? "nil"
            let to = String(describing: self)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(from) -> \(to)")
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(String(describing: self))")
        }
    }
}

extension FavoriteViewModel.State {
    class Initial: FavoriteViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard viewModel != nil else { return false }
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: FavoriteViewModel.State {
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
            viewModel.statusFetchedResultsController.statusIDs = []
            
            stateMachine.enter(Loading.self)
        }
    }
    
    class Fail: FavoriteViewModel.State {
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
            
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading 3s later…", ((#file as NSString).lastPathComponent), #line, #function)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading", ((#file as NSString).lastPathComponent), #line, #function)
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Idle: FavoriteViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: FavoriteViewModel.State {
        
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
            guard let viewModel else { return }
            
            if previousState is Reloading {
                maxID = nil
            }
            
            Task {
                do {
                    let response = try await viewModel.context.apiService.favoritedStatuses(
                        maxID: maxID,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    var hasNewStatusesAppend = false
                    var statusIDs = viewModel.statusFetchedResultsController.statusIDs
                    for status in response.value {
                        guard !statusIDs.contains(status.id) else { continue }
                        statusIDs.append(status.id)
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
                    viewModel.statusFetchedResultsController.statusIDs = statusIDs
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch user favorites fail: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }
    
    class NoMore: FavoriteViewModel.State {
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
