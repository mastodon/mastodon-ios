//
//  PublicTimelineViewModel+LoadMiddleState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/4.
//

import CoreData
import CoreDataStack
import Foundation
import GameplayKit
import os.log

extension PublicTimelineViewModel {
    class LoadMiddleState: GKState {
        weak var viewModel: PublicTimelineViewModel?
        let upperTimelineStatusID: String
        
        init(viewModel: PublicTimelineViewModel, upperTimelineStatusID: String) {
            self.viewModel = viewModel
            self.upperTimelineStatusID = upperTimelineStatusID
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", (#file as NSString).lastPathComponent, #line, #function, self.debugDescription, previousState.debugDescription)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            var dict = viewModel.loadMiddleSateMachineList.value
            dict[self.upperTimelineStatusID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict // trigger value change
        }
    }
}

extension PublicTimelineViewModel.LoadMiddleState {
    class Initial: PublicTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: PublicTimelineViewModel.LoadMiddleState {
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
            viewModel.context.apiService.publicTimeline(
                domain: activeMastodonAuthenticationBox.domain,
                maxID: upperTimelineStatusID
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch statuses failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                }
            } receiveValue: { response in
                let statuses = response.value
                let addedStatuses = statuses.filter { !viewModel.statusIDs.value.contains($0.id) }
                
                guard let gapIndex = viewModel.statusIDs.value.firstIndex(of: self.upperTimelineStatusID) else { return }
                let upStatuses = Array(viewModel.statusIDs.value[...gapIndex])
                let downStatuses = Array(viewModel.statusIDs.value[(gapIndex + 1)...])
                
                // construct newStatusIDs
                var newStatusIDs = upStatuses
                newStatusIDs.append(contentsOf: addedStatuses.map { $0.id })
                newStatusIDs.append(contentsOf: downStatuses)
                // remove old gap from viewmodel
                if let index = viewModel.statusIDsWhichHasGap.firstIndex(of: self.upperTimelineStatusID) {
                    viewModel.statusIDsWhichHasGap.remove(at: index)
                }
                // add new gap from viewmodel if need
                let intersection = statuses.filter { downStatuses.contains($0.id) }
                if intersection.isEmpty {
                    addedStatuses.last.flatMap { viewModel.statusIDsWhichHasGap.append($0.id) }
                }
                
                viewModel.statusIDs.value = newStatusIDs
                os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld statuses, %{public}%ld new statues", (#file as NSString).lastPathComponent, #line, #function, statuses.count, addedStatuses.count)
                if addedStatuses.isEmpty {
                    stateMachine.enter(Fail.self)
                } else {
                    stateMachine.enter(Success.self)
                }
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: PublicTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Success: PublicTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return false
        }
    }
}
