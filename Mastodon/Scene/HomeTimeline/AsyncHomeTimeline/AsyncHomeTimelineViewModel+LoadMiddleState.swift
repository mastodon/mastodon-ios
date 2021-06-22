//
//  AsyncHomeTimelineViewModel+LoadMiddleState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-21.
//

#if ASDK

import os.log
import Foundation
import GameplayKit
import CoreData
import CoreDataStack

extension AsyncHomeTimelineViewModel {
    class LoadMiddleState: GKState {
        weak var viewModel: AsyncHomeTimelineViewModel?
        let upperTimelineIndexObjectID: NSManagedObjectID
        
        init(viewModel: AsyncHomeTimelineViewModel, upperTimelineIndexObjectID: NSManagedObjectID) {
            self.viewModel = viewModel
            self.upperTimelineIndexObjectID = upperTimelineIndexObjectID
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            var dict = viewModel.loadMiddleSateMachineList.value
            dict[upperTimelineIndexObjectID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict    // trigger value change
        }
    }
}

extension AsyncHomeTimelineViewModel.LoadMiddleState {
    
    class Initial: AsyncHomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: AsyncHomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Success.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let timelineIndex = (viewModel.fetchedResultsController.fetchedObjects ?? []).first(where: { $0.objectID == upperTimelineIndexObjectID }) else {
                stateMachine.enter(Fail.self)
                return
            }
            let statusIDs = (viewModel.fetchedResultsController.fetchedObjects ?? []).compactMap { timelineIndex in
                timelineIndex.status.id
            }

            // TODO: only set large count when using Wi-Fi
            let maxID = timelineIndex.status.id
            viewModel.context.apiService.homeTimeline(domain: activeMastodonAuthenticationBox.domain,maxID: maxID, authorizationBox: activeMastodonAuthenticationBox)
                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(completion)
                    switch completion {
                    case .failure(let error):
                        // TODO: handle error
                        os_log("%{public}s[%{public}ld], %{public}s: fetch statuses failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    let statuses = response.value
                    let newStatuses = statuses.filter { !statusIDs.contains($0.id) }
                    os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld statuses, %{public}%ld new statuses", ((#file as NSString).lastPathComponent), #line, #function, statuses.count, newStatuses.count)
                    if newStatuses.isEmpty {
                        stateMachine.enter(Fail.self)
                    } else {
                        stateMachine.enter(Success.self)
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: AsyncHomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Success: AsyncHomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return false
        }
    }
    
}

#endif
