//
//  HashtagTimelineViewModel+LoadLatestState.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import os.log
import UIKit
import GameplayKit
import CoreData
import CoreDataStack
import MastodonSDK

extension HashtagTimelineViewModel {
    class LoadLatestState: GKState {
        weak var viewModel: HashtagTimelineViewModel?
        
        init(viewModel: HashtagTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.loadLatestStateMachinePublisher.send(self)
        }
    }
}

extension HashtagTimelineViewModel.LoadLatestState {
    class Initial: HashtagTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: HashtagTimelineViewModel.LoadLatestState {
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
            // TODO: only set large count when using Wi-Fi
            viewModel.context.apiService.hashtagTimeline(
                domain: activeMastodonAuthenticationBox.domain,
                hashtag: viewModel.hashTag,
                authorizationBox: activeMastodonAuthenticationBox)
                .receive(on: DispatchQueue.main)
                .sink { completion in
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
                    let newStatusIDList = response.value.map { $0.id }
                    
                    // When response data:
                    // 1. is not empty
                    // 2. last status are not recorded
                    // Then we may have middle data to load
                    if !viewModel.hashtagStatusIDList.isEmpty, let lastNewStatusID = newStatusIDList.last,
                       !viewModel.hashtagStatusIDList.contains(lastNewStatusID) {
                        viewModel.needLoadMiddleIndex = (newStatusIDList.count - 1)
                    } else {
                        viewModel.needLoadMiddleIndex = nil
                    }
                    
                    viewModel.hashtagStatusIDList.insert(contentsOf: newStatusIDList, at: 0)
                    viewModel.hashtagStatusIDList.removeDuplicates()
                    
                    let newPredicate = Toot.predicate(domain: activeMastodonAuthenticationBox.domain, ids: viewModel.hashtagStatusIDList)
                    viewModel.timelinePredicate.send(newPredicate)
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: HashtagTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: HashtagTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
}
