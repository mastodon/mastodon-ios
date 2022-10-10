//
//  HomeTimelineViewModel+LoadOldestState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension HomeTimelineViewModel {
    class LoadOldestState: GKState {
        
        let logger = Logger(subsystem: "HomeTimelineViewModel.LoadOldestState", category: "StateMachine")
        
        let id = UUID()
        
        weak var viewModel: HomeTimelineViewModel?
        
        init(viewModel: HomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            let from = previousState.flatMap { String(describing: $0) } ?? "nil"
            let to = String(describing: self)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(from) -> \(to)")
        }
        
        @MainActor
        func enter(state: LoadOldestState.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(String(describing: self))")
        }
    }
}

extension HomeTimelineViewModel.LoadOldestState {
    class Initial: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard !viewModel.fetchedResultsController.records.isEmpty else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let lastFeedRecord = viewModel.fetchedResultsController.records.last else {
                stateMachine.enter(Idle.self)
                return
            }
            
            Task {
                let managedObjectContext = viewModel.fetchedResultsController.fetchedResultsController.managedObjectContext
                let _maxID: Mastodon.Entity.Status.ID? = try await managedObjectContext.perform {
                    guard let feed = lastFeedRecord.object(in: managedObjectContext),
                          let status = feed.status
                    else { return nil }
                    return status.id
                }
                
                guard let maxID = _maxID else {
                    await self.enter(state: Fail.self)
                    return
                }

                do {
                    let response = try await viewModel.context.apiService.homeTimeline(
                        maxID: maxID,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    let statuses = response.value
                    // enter no more state when no new statuses
                    if statuses.isEmpty || (statuses.count == 1 && statuses[0].id == maxID) {
                        await self.enter(state: NoMore.self)
                    } else {
                        await self.enter(state: Idle.self)
                    }
                    
                    viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(.finished)
                    
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch statues failed: \(error.localizedDescription)")
                    await self.enter(state: Fail.self)
                    viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(.failure(error))
                }
            }   // end Task
        }
    }
    
    class Fail: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

    class NoMore: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // reset state if needs
            return stateClass == Idle.self
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
