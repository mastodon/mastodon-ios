//
//  DiscoveryPostsViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import Foundation
import GameplayKit
import MastodonSDK
import MastodonCore

extension DiscoveryPostsViewModel {
    class State: GKState {
        let id = UUID()

        weak var viewModel: DiscoveryPostsViewModel?
        
        init(viewModel: DiscoveryPostsViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension DiscoveryPostsViewModel.State {
    class Initial: DiscoveryPostsViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: DiscoveryPostsViewModel.State {
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
    
    class Fail: DiscoveryPostsViewModel.State {
        
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
    
    class Idle: DiscoveryPostsViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: DiscoveryPostsViewModel.State {
        
        var offset: Int?
        
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
                offset = nil
            default:
                break
            }
            
            let offset = self.offset
            let isReloading = offset == nil
            
            Task {
                do {
                    let response = try await viewModel.context.apiService.trendStatuses(
                        domain: viewModel.authContext.mastodonAuthenticationBox.domain,
                        query: Mastodon.API.Trends.StatusQuery(
                            offset: offset,
                            limit: nil
                        ),
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    let newOffset: Int? = {
                        guard let offset = response.link?.offset else { return nil }
                        return self.offset.flatMap { max($0, offset) } ?? offset
                    }()
                    
                    let hasMore: Bool = {
                        guard let newOffset = newOffset else { return false }
                        return newOffset != self.offset     // not the same one
                    }()
                    
                    self.offset = newOffset

                    var hasNewStatusesAppend = false
                    var statusIDs = isReloading ? [] : await viewModel.statusFetchedResultsController.records
                    for status in response.value {
                        guard !statusIDs.contains(where: { $0.id == status.id }) else { continue }
                        statusIDs.append(.fromEntity(status))
                        hasNewStatusesAppend = true
                    }

                    if hasNewStatusesAppend, hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    await viewModel.statusFetchedResultsController.setRecords(statusIDs)
                    viewModel.didLoadLatest.send()
                    
                } catch {
                    if let error = error as? Mastodon.API.Error {
                        if error.httpResponseStatus == .notFound {
                            viewModel.isServerSupportEndpoint = false
                            await enter(state: NoMore.self)
                        } else if error.httpResponseStatus == .unauthorized {
                            await enter(state: NoMore.self)
                        }
                    } else {
                        await enter(state: Fail.self)
                    }
                    
                    viewModel.didLoadLatest.send()
                }
            }   // end Task
        }   // end func
    }
    
    class NoMore: DiscoveryPostsViewModel.State {
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
