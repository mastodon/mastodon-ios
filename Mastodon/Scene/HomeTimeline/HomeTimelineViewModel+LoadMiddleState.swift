//
//  HomeTimelineViewModel+LoadMiddleState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import os.log
import Foundation
import GameplayKit
import CoreData
import CoreDataStack

extension HomeTimelineViewModel {
    class LoadMiddleState: GKState {
        weak var viewModel: HomeTimelineViewModel?
        let upperTimelineIndexObjectID: NSManagedObjectID
        
        init(viewModel: HomeTimelineViewModel, upperTimelineIndexObjectID: NSManagedObjectID) {
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

extension HomeTimelineViewModel.LoadMiddleState {
    
    class Initial: HomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: HomeTimelineViewModel.LoadMiddleState {
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
            let tootIDs = (viewModel.fetchedResultsController.fetchedObjects ?? []).compactMap { timelineIndex in
                timelineIndex.toot.id
            }

            // TODO: only set large count when using Wi-Fi
            let maxID = timelineIndex.toot.id
            viewModel.context.apiService.homeTimeline(domain: activeMastodonAuthenticationBox.domain,maxID: maxID, authorizationBox: activeMastodonAuthenticationBox)
                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        // TODO: handle error
                        os_log("%{public}s[%{public}ld], %{public}s: fetch toots failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    let toots = response.value
                    let newToots = toots.filter { !tootIDs.contains($0.id) }
                    os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld toots, %{public}%ld new toots", ((#file as NSString).lastPathComponent), #line, #function, toots.count, newToots.count)
                    if newToots.isEmpty {
                        stateMachine.enter(Fail.self)
                    } else {
                        stateMachine.enter(Success.self)
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: HomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Success: HomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return false
        }
    }
    
}
