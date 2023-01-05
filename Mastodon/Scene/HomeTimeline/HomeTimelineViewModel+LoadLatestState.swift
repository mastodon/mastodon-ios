//
//  HomeTimelineViewModel+LoadLatestState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import os.log
import func QuartzCore.CACurrentMediaTime
import Foundation
import CoreData
import CoreDataStack
import GameplayKit
import MastodonCore

extension HomeTimelineViewModel {
    class LoadLatestState: GKState {
        
        let logger = Logger(subsystem: "HomeTimelineViewModel.LoadLatestState", category: "StateMachine")

        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        
        weak var viewModel: HomeTimelineViewModel?
        
        init(viewModel: HomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? HomeTimelineViewModel.LoadLatestState
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
            viewModel?.loadLatestStateMachinePublisher.send(self)
        }
        
        @MainActor
        func enter(state: LoadLatestState.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension HomeTimelineViewModel.LoadLatestState {
    class Initial: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel else { return }
            
            let latestFeedRecords = viewModel.fetchedResultsController.records.prefix(APIService.onceRequestStatusMaxCount)
            let parentManagedObjectContext = viewModel.fetchedResultsController.fetchedResultsController.managedObjectContext
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.parent = parentManagedObjectContext

            Task {
                let start = CACurrentMediaTime()
                let latestStatusIDs: [Status.ID] = latestFeedRecords.compactMap { record in
                    guard let feed = record.object(in: managedObjectContext) else { return nil }
                    return feed.status?.id
                }
                let end = CACurrentMediaTime()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: collect statuses id cost: %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)

                do {
                    let response = try await viewModel.context.apiService.homeTimeline(
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    await enter(state: Idle.self)
                    viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(.finished)

                    viewModel.context.instanceService.updateMutesAndBlocks()
                    
                    // stop refresher if no new statuses
                    let statuses = response.value
                    let newStatuses = statuses.filter { !latestStatusIDs.contains($0.id) }
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): load \(newStatuses.count) new statuses")
                    
                    if newStatuses.isEmpty {
                        viewModel.didLoadLatest.send()
                    } else {
                        if !latestStatusIDs.isEmpty {
                            viewModel.homeTimelineNavigationBarTitleViewModel.newPostsIncoming()
                        }
                    }
                    viewModel.timelineIsEmpty.value = latestStatusIDs.isEmpty && statuses.isEmpty
                    
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch statuses failed: \(error.localizedDescription)")
                    await enter(state: Idle.self)
                    viewModel.didLoadLatest.send()
                    viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(.failure(error))
                }   
            }   // end Task
        }
    }
    
    class Fail: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

}
