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

extension HomeTimelineViewModel {
    class LoadLatestState: GKState {
        weak var viewModel: HomeTimelineViewModel?
        
        init(viewModel: HomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.loadLatestStateMachinePublisher.send(self)
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
                let latestTootIDs: [Toot.ID]
                let request = HomeTimelineIndex.sortedFetchRequest
                request.returnsObjectsAsFaults = false
                request.predicate = predicate

                do {
                    let timelineIndexes = try managedObjectContext.fetch(request)
                    let endFetch = CACurrentMediaTime()
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: collect timelineIndexes cost: %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endFetch - start)
                    latestTootIDs = timelineIndexes
                        .prefix(APIService.onceRequestTootMaxCount)        // avoid performance issue
                        .compactMap { timelineIndex in
                            timelineIndex.value(forKeyPath: #keyPath(HomeTimelineIndex.toot.id)) as? Toot.ID
                        }
                } catch {
                    stateMachine.enter(Fail.self)
                    return
                }
                viewModel.homeTimelineNavigationBarState.hasContentBeforeFetching = !latestTootIDs.isEmpty
                let end = CACurrentMediaTime()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: collect toots id cost: %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
                
                // TODO: only set large count when using Wi-Fi
                viewModel.context.apiService.homeTimeline(domain: activeMastodonAuthenticationBox.domain, authorizationBox: activeMastodonAuthenticationBox)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        viewModel.homeTimelineNavigationBarState.receiveCompletion(completion: completion)
                        switch completion {
                        case .failure(let error):
                            // TODO: handle error
                            viewModel.isFetchingLatestTimeline.value = false
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch toots failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        case .finished:
                            // handle isFetchingLatestTimeline in fetch controller delegate
                            break
                        }
                        
                        stateMachine.enter(Idle.self)
                        
                    } receiveValue: { response in
                        // stop refresher if no new toots
                        let toots = response.value
                        let newToots = toots.filter { !latestTootIDs.contains($0.id) }
                        os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld new toots", ((#file as NSString).lastPathComponent), #line, #function, newToots.count)
                        
                        if newToots.isEmpty {
                            viewModel.isFetchingLatestTimeline.value = false
                            viewModel.homeTimelineNavigationBarState.newTopContent.value = false
                        } else {
                            viewModel.homeTimelineNavigationBarState.newTopContent.value = true
                        }
                    }
                    .store(in: &viewModel.disposeBag)
            }
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
