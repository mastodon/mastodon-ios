//
//  DiscoveryNewsViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension DiscoveryNewsViewModel {
    class State: GKState, NamingState {
        
        let logger = Logger(subsystem: "DiscoveryNewsViewModel.State", category: "StateMachine")

        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        
        weak var viewModel: DiscoveryNewsViewModel?
        
        init(viewModel: DiscoveryNewsViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? DiscoveryNewsViewModel.State
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension DiscoveryNewsViewModel.State {
    class Initial: DiscoveryNewsViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: DiscoveryNewsViewModel.State {
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
            
            viewModel.links = []

            stateMachine.enter(Loading.self)
        }
    }
    
    class Fail: DiscoveryNewsViewModel.State {
        
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
    
    class Idle: DiscoveryNewsViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: DiscoveryNewsViewModel.State {
        
        var offset: Int?
        var isReloading: Bool { return offset == nil }
        
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
            
            
            switch previousState {
            case is Reloading:
                offset = nil
            default:
                break
            }

            guard let authenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let offset = self.offset
            
            Task {
                do {
                    let response = try await viewModel.context.apiService.trendLinks(
                        domain: authenticationBox.domain,
                        query: Mastodon.API.Trends.StatusQuery(
                            offset: offset,
                            limit: nil
                        )
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

                    var hasNewItemsAppend = false
                    var links = viewModel.links
                    for link in response.value {
                        guard !links.contains(link) else { continue }
                        links.append(link)
                        hasNewItemsAppend = true
                    }

                    if hasNewItemsAppend, hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    viewModel.links = links
                    viewModel.didLoadLatest.send()
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch news fail: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                    viewModel.didLoadLatest.send()
                }
            }   // end Task
        }   // end func
    }
    
    class NoMore: DiscoveryNewsViewModel.State {
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
