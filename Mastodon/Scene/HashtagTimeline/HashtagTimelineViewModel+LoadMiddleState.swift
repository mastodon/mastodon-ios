//
//  HashtagTimelineViewModel+LoadMiddleState.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/31.
//

import os.log
import Foundation
import GameplayKit
import CoreData
import CoreDataStack

extension HashtagTimelineViewModel {
    class LoadMiddleState: GKState {
        weak var viewModel: HashtagTimelineViewModel?
        let upperStatusObjectID: NSManagedObjectID
        
        init(viewModel: HashtagTimelineViewModel, upperStatusObjectID: NSManagedObjectID) {
            self.viewModel = viewModel
            self.upperStatusObjectID = upperStatusObjectID
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            var dict = viewModel.loadMiddleSateMachineList.value
            dict[upperStatusObjectID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict    // trigger value change
        }
    }
}

extension HashtagTimelineViewModel.LoadMiddleState {
    
    class Initial: HashtagTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: HashtagTimelineViewModel.LoadMiddleState {
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
            
            guard let upperStatusObject = (viewModel.fetchedResultsController.fetchedResultsController.fetchedObjects ?? []).first(where: { $0.objectID == upperStatusObjectID }) else {
                stateMachine.enter(Fail.self)
                return
            }
            let statusIDs = (viewModel.fetchedResultsController.fetchedResultsController.fetchedObjects ?? []).compactMap { status in
                status.id
            }

            // TODO: only set large count when using Wi-Fi
            let maxID = upperStatusObject.id
            viewModel.context.apiService.hashtagTimeline(
                domain: activeMastodonAuthenticationBox.domain,
                maxID: maxID,
                hashtag: viewModel.hashTag,
                authorizationBox: activeMastodonAuthenticationBox)
                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { completion in
//                    viewModel.homeTimelineNavigationBarState.receiveCompletion(completion: completion)
                    switch completion {
                    case .failure(let error):
                        // TODO: handle error
                        os_log("%{public}s[%{public}ld], %{public}s: fetch statuses failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    stateMachine.enter(Success.self)
                    
                    let newStatusIDList = response.value.map { $0.id }
                    
                    var oldStatusIDs = viewModel.fetchedResultsController.statusIDs.value
                    if let indexToInsert = oldStatusIDs.firstIndex(of: maxID) {
                        // When response data:
                        // 1. is not empty
                        // 2. last status are not recorded
                        // Then we may have middle data to load
                        if let lastNewStatusID = newStatusIDList.last,
                           !oldStatusIDs.contains(lastNewStatusID) {
                            viewModel.needLoadMiddleIndex = indexToInsert + newStatusIDList.count
                        } else {
                            viewModel.needLoadMiddleIndex = nil
                        }
                        oldStatusIDs.insert(contentsOf: newStatusIDList, at: indexToInsert + 1)
                        oldStatusIDs.removeDuplicates()
                    } else {
                        // Only when the hashtagStatusIDList changes, we could not find the `loadMiddleState` index
                        // Then there is no need to set a `loadMiddleState` cell
                        viewModel.needLoadMiddleIndex = nil
                    }
                    
                    viewModel.fetchedResultsController.statusIDs.value = oldStatusIDs
                    
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: HashtagTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Success: HashtagTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return false
        }
    }
    
}

