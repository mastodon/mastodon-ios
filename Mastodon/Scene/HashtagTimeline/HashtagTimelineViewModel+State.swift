//
//  HashtagTimelineViewModel+State.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/31.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack

extension HashtagTimelineViewModel {
    class State: GKState {
        
        let logger = Logger(subsystem: "HashtagTimelineViewModel.LoadOldestState", category: "StateMachine")
        
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }

        weak var viewModel: HashtagTimelineViewModel?
        
        init(viewModel: HashtagTimelineViewModel) {
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
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
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
            
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading 3s later…", ((#file as NSString).lastPathComponent), #line, #function)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading", ((#file as NSString).lastPathComponent), #line, #function)
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
                        domain: viewModel.authContext.mastodonAuthenticationBox.domain,
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
                    var statusIDs = isReloading ? [] : viewModel.fetchedResultsController.statusIDs
                    for status in response.value {
                        guard !statusIDs.contains(status.id) else { continue }
                        statusIDs.append(status.id)
                        hasNewStatusesAppend = true
                    }

                    if hasNewStatusesAppend, hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    
                    viewModel.fetchedResultsController.append(statusIDs: statusIDs)
                    viewModel.didLoadLatest.send()
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch statues failed: \(error.localizedDescription)")
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

