//
//  HashtagTimelineViewModel+LoadOldestState.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/31.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack

extension HashtagTimelineViewModel {
    class LoadOldestState: GKState, NamingState {
        
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
            let previousState = previousState as? HashtagTimelineViewModel.LoadOldestState
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")

            viewModel?.loadOldestStateMachinePublisher.send(self)
        }
        
        @MainActor
        func enter(state: LoadOldestState.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension HashtagTimelineViewModel.LoadOldestState {
    class Initial: HashtagTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: HashtagTimelineViewModel.LoadOldestState {
        var maxID: Status.ID?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }
            
            // TODO: only set large count when using Wi-Fi
            let maxID = self.maxID
            Task {
                do {
                    let response = try await viewModel.context.apiService.hashtagTimeline(
                        domain: authenticationBox.domain,
                        maxID: maxID,
                        hashtag: viewModel.hashtag,
                        authenticationBox: authenticationBox
                    )
                    
                    var hasMore = false
                    
                    if let _maxID = response.link?.maxID,
                        _maxID != maxID
                    {
                        self.maxID = _maxID
                        hasMore = true
                    }
                    if hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    
                    let statusIDs = response.value.map { $0.id }
                    viewModel.fetchedResultsController.append(statusIDs: statusIDs)
                    
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch statues failed: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }   // end Task
        }
    }
    
    class Fail: HashtagTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: HashtagTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

    class NoMore: HashtagTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
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

