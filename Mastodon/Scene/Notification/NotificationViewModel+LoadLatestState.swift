//
//  NotificationViewModel+LoadLatestState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import CoreDataStack
import Foundation
import GameplayKit
import MastodonSDK
import os.log
import func QuartzCore.CACurrentMediaTime

extension NotificationViewModel {
    class LoadLatestState: GKState {
        weak var viewModel: NotificationViewModel?
        
        init(viewModel: NotificationViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", (#file as NSString).lastPathComponent, #line, #function, debugDescription, previousState.debugDescription)
            viewModel?.loadLatestStateMachinePublisher.send(self)
        }
    }
}

extension NotificationViewModel.LoadLatestState {
    class Initial: NotificationViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Loading.self
        }
    }
    
    class Loading: NotificationViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.activeMastodonAuthenticationBox.value else {
                // sign out when loading will enter here
                stateMachine.enter(Fail.self)
                return
            }
            let query = Mastodon.API.Notifications.Query(
                maxID: nil,
                sinceID: nil,
                minID: nil,
                limit: nil,
                excludeTypes: [],
                accountID: nil
            )
            viewModel.context.apiService.allNotifications(
                domain: activeMastodonAuthenticationBox.domain,
                query: query,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox
            )
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        viewModel.isFetchingLatestNotification.value = false
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch notification failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                    case .finished:
                        // handle isFetchingLatestTimeline in fetch controller delegate
                        break
                    }
                    
                    stateMachine.enter(Idle.self)
                } receiveValue: { response in
                    if response.value.isEmpty {
                        viewModel.isFetchingLatestNotification.value = false
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: NotificationViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: NotificationViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Loading.self
        }
    }
}
