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
        let upperTimelineTootID: String
        
        init(viewModel: PublicTimelineViewModel, upperTimelineTootID: String) {
            self.viewModel = viewModel
            self.upperTimelineTootID = upperTimelineTootID
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", (#file as NSString).lastPathComponent, #line, #function, self.debugDescription, previousState.debugDescription)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            var dict = viewModel.loadMiddleSateMachineList.value
            dict[self.upperTimelineTootID] = stateMachine
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
            let maxID = upperTimelineTootID
            viewModel.context.apiService.publicTimeline(
                domain: activeMastodonAuthenticationBox.domain,
                maxID: maxID
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                }
            } receiveValue: { response in
                let toots = response.value
                let addedToots = toots.filter { !viewModel.tootIDs.value.contains($0.id) }
                
                guard let gapIndex = viewModel.tootIDs.value.firstIndex(of: self.upperTimelineTootID) else { return }
                let upToots = Array(viewModel.tootIDs.value[0...(gapIndex-1)])
                let downToots = Array(viewModel.tootIDs.value[gapIndex...viewModel.tootIDs.value.count-1])
                
                // construct newTootIDs
                var newTootIDs = upToots
                newTootIDs.append(contentsOf: addedToots.map { $0.id })
                newTootIDs.append(contentsOf: downToots)
                // remove old gap from viewmodel
                if let index = viewModel.tootIDsWhichHasGap.firstIndex(of: self.upperTimelineTootID) {
                    viewModel.tootIDsWhichHasGap.remove(at: index)
                }
                // add new gap from viewmodel if need
                let intersection = toots.filter { upToots.contains($0.id) }
                if intersection.isEmpty {
                    toots.first.flatMap { viewModel.tootIDsWhichHasGap.append($0.id) }
                }
                
                viewModel.tootIDs.value = newTootIDs
                os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld tweets, %{public}%ld new tweets", (#file as NSString).lastPathComponent, #line, #function, toots.count, addedToots.count)
                if addedToots.isEmpty {
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
