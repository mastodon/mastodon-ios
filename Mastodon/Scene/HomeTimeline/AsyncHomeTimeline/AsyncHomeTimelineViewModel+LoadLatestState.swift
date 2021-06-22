//
//  AsyncHomeTimelineViewModel+LoadLatestState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-21.
//
//

#if ASDK

import os.log
import func QuartzCore.CACurrentMediaTime
import Foundation
import CoreData
import CoreDataStack
import GameplayKit

extension AsyncHomeTimelineViewModel {
    class LoadLatestState: GKState {
        weak var viewModel: AsyncHomeTimelineViewModel?
        
        init(viewModel: AsyncHomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.loadLatestStateMachinePublisher.send(self)
        }
    }
}

extension AsyncHomeTimelineViewModel.LoadLatestState {
    class Initial: AsyncHomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: AsyncHomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                // sign out when loading will enter here
                stateMachine.enter(Fail.self)
                return
            }
            
            let predicate = viewModel.fetchedResultsController.fetchRequest.predicate
            let parentManagedObjectContext = viewModel.fetchedResultsController.managedObjectContext
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.parent = parentManagedObjectContext

            managedObjectContext.perform {
                let start = CACurrentMediaTime()
                let latestStatusIDs: [Status.ID]
                let request = HomeTimelineIndex.sortedFetchRequest
                request.returnsObjectsAsFaults = false
                request.predicate = predicate

                do {
                    let timelineIndexes = try managedObjectContext.fetch(request)
                    let endFetch = CACurrentMediaTime()
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: collect timelineIndexes cost: %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endFetch - start)
                    latestStatusIDs = timelineIndexes
                        .prefix(APIService.onceRequestStatusMaxCount)        // avoid performance issue
                        .compactMap { timelineIndex in
                            timelineIndex.value(forKeyPath: #keyPath(HomeTimelineIndex.status.id)) as? Status.ID
                        }
                } catch {
                    stateMachine.enter(Fail.self)
                    return
                }

                let end = CACurrentMediaTime()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: collect statuses id cost: %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
                
                // TODO: only set large count when using Wi-Fi
                viewModel.context.apiService.homeTimeline(domain: activeMastodonAuthenticationBox.domain, authorizationBox: activeMastodonAuthenticationBox)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(completion)
                        switch completion {
                        case .failure(let error):
                            // TODO: handle error
                            viewModel.isFetchingLatestTimeline.value = false
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch statuses failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        case .finished:
                            // handle isFetchingLatestTimeline in fetch controller delegate
                            break
                        }
                        
                        stateMachine.enter(Idle.self)
                        
                    } receiveValue: { response in
                        // stop refresher if no new statuses
                        let statuses = response.value
                        let newStatuses = statuses.filter { !latestStatusIDs.contains($0.id) }
                        os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld new statuses", ((#file as NSString).lastPathComponent), #line, #function, newStatuses.count)
                        
                        if newStatuses.isEmpty {
                            viewModel.isFetchingLatestTimeline.value = false
                        } else {
                            if !latestStatusIDs.isEmpty {
                                viewModel.homeTimelineNavigationBarTitleViewModel.newPostsIncoming()
                            }
                        }
                        viewModel.timelineIsEmpty.value = latestStatusIDs.isEmpty && statuses.isEmpty
                    }
                    .store(in: &viewModel.disposeBag)
            }
        }
    }
    
    class Fail: AsyncHomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: AsyncHomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

}

#endif
