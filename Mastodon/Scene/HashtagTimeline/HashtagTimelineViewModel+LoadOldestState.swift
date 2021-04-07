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
    class LoadOldestState: GKState {
        weak var viewModel: HashtagTimelineViewModel?
        
        init(viewModel: HashtagTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.loadOldestStateMachinePublisher.send(self)
        }
    }
}

extension HashtagTimelineViewModel.LoadOldestState {
    class Initial: HashtagTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard !(viewModel.fetchedResultsController.fetchedResultsController.fetchedObjects ?? []).isEmpty else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: HashtagTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let last = viewModel.fetchedResultsController.fetchedResultsController.fetchedObjects?.last else {
                stateMachine.enter(Idle.self)
                return
            }
            
            // TODO: only set large count when using Wi-Fi
            let maxID = last.id
            viewModel.context.apiService.hashtagTimeline(
                domain: activeMastodonAuthenticationBox.domain,
                maxID: maxID,
                hashtag: viewModel.hashtag,
                authorizationBox: activeMastodonAuthenticationBox)
                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { completion in
//                    viewModel.homeTimelineNavigationBarState.receiveCompletion(completion: completion)
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch statuses failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    case .finished:
                        // handle isFetchingLatestTimeline in fetch controller delegate
                        break
                    }
                } receiveValue: { response in
                    let statuses = response.value
                    // enter no more state when no new statuses
                    if statuses.isEmpty || (statuses.count == 1 && statuses[0].id == maxID) {
                        stateMachine.enter(NoMore.self)
                    } else {
                        stateMachine.enter(Idle.self)
                    }
                    var newStatusIDs = viewModel.fetchedResultsController.statusIDs.value
                    let fetchedStatusIDList = statuses.map { $0.id }
                    newStatusIDs.append(contentsOf: fetchedStatusIDList)
                    viewModel.fetchedResultsController.statusIDs.value = newStatusIDs
                }
                .store(in: &viewModel.disposeBag)
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
            // reset state if needs
            return stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            guard let viewModel = viewModel else { return }
            guard let diffableDataSource = viewModel.diffableDataSource else {
                assertionFailure()
                return
            }
            var snapshot = diffableDataSource.snapshot()
            snapshot.deleteItems([.bottomLoader])
            diffableDataSource.apply(snapshot)
        }
    }
}

