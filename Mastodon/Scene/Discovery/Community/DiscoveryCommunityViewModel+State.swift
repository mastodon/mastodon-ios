//
//  DiscoveryCommunityViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-29.
//

import Foundation
import GameplayKit
import MastodonSDK
import enum NIOHTTP1.HTTPResponseStatus

extension DiscoveryCommunityViewModel {
    class State: GKState {

        let id = UUID()
        
        weak var viewModel: DiscoveryCommunityViewModel?
        
        init(viewModel: DiscoveryCommunityViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension DiscoveryCommunityViewModel.State {
    class Initial: DiscoveryCommunityViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: DiscoveryCommunityViewModel.State {
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

            stateMachine.enter(Loading.self)
        }
    }
    
    class Fail: DiscoveryCommunityViewModel.State {
        
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
    
    class Idle: DiscoveryCommunityViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: DiscoveryCommunityViewModel.State {
        
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
                        
            switch previousState {
            case is Reloading:
                maxID = nil
            default:
                break
            }
            
            let maxID = self.maxID
            let isReloading = maxID == nil

            Task {
                do {
                    let response = try await viewModel.context.apiService.publicTimeline(
                        query: .init(
                            local: true,
                            remote: nil,
                            onlyMedia: nil,
                            maxID: maxID,
                            sinceID: nil,
                            minID: nil,
                            limit: 20
                        ),
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    let newMaxID = response.link?.maxID
                    let hasMore = newMaxID != nil
                    self.maxID = newMaxID
                    
                    var hasNewStatusesAppend = false
                    var statusIDs = isReloading ? [] : viewModel.statusFetchedResultsController.statusIDs
                    for status in response.value {
                        guard !statusIDs.contains(status.id) else { continue }
                        statusIDs.append(status.id)
                        hasNewStatusesAppend = true
                    }
                    
                    if hasNewStatusesAppend, hasMore {
                        self.maxID = response.link?.maxID
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    viewModel.statusFetchedResultsController.statusIDs = statusIDs
                    viewModel.didLoadLatest.send()
                    
                } catch {
                    if let error = error as? Mastodon.API.Error,
                       [HTTPResponseStatus.unauthorized, .notFound].contains(error.httpResponseStatus) {
                        await enter(state: NoMore.self)
                    } else {
                        await enter(state: Fail.self)
                    }
                }
            }   // end Task
        }   // end func
    }
    
    class NoMore: DiscoveryCommunityViewModel.State {
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
