//
//  NotificationViewModel+LoadOldestState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/14.
//

import CoreDataStack
import Foundation
import GameplayKit
import MastodonSDK
import os.log

extension NotificationViewModel {
    class LoadOldestState: GKState {
        weak var viewModel: NotificationViewModel?
        
        init(viewModel: NotificationViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", (#file as NSString).lastPathComponent, #line, #function, debugDescription, previousState.debugDescription)
            viewModel?.loadOldestStateMachinePublisher.send(self)
        }
    }
}

extension NotificationViewModel.LoadOldestState {
    class Initial: NotificationViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard !(viewModel.fetchedResultsController.fetchedObjects ?? []).isEmpty else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: NotificationViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.activeMastodonAuthenticationBox.value else {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }
            let notifications: [MastodonNotification]? = {
                let request = MastodonNotification.sortedFetchRequest
                request.predicate = MastodonNotification.predicate(domain: activeMastodonAuthenticationBox.domain)
                request.returnsObjectsAsFaults = false
                do {
                    return try self.viewModel?.context.managedObjectContext.fetch(request)
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            }()
            
            guard let last = notifications?.last else {
                stateMachine.enter(Idle.self)
                return
            }
            
            let maxID = last.id
            let query = Mastodon.API.Notifications.Query(
                maxID: maxID,
                sinceID: nil,
                minID: nil,
                limit: nil,
                excludeTypes: Mastodon.API.Notifications.allExcludeTypes(),
                accountID: nil)
            viewModel.context.apiService.allNotifications(
                domain: activeMastodonAuthenticationBox.domain,
                query: query,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch notification failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                    case .finished:
                        // handle isFetchingLatestTimeline in fetch controller delegate
                        break
                    }
                    
                    stateMachine.enter(Idle.self)
                } receiveValue: { [weak viewModel] response in
                    guard let viewModel = viewModel else { return }
                    if viewModel.selectedIndex.value == 1 {
                        viewModel.noMoreNotification.value = response.value.isEmpty
                        let list = response.value.filter { $0.type == Mastodon.Entity.Notification.NotificationType.mention }
                        if list.isEmpty {
                            stateMachine.enter(NoMore.self)
                        } else {
                            stateMachine.enter(Idle.self)
                        }
                    } else {
                        if response.value.isEmpty {
                            stateMachine.enter(NoMore.self)
                        } else {
                            stateMachine.enter(Idle.self)
                        }
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: NotificationViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: NotificationViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Loading.self
        }
    }

    class NoMore: NotificationViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // reset state if needs
            stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            guard let viewModel = viewModel else { return }
            guard let diffableDataSource = viewModel.diffableDataSource else {
                assertionFailure()
                return
            }
            DispatchQueue.main.async {
                var snapshot = diffableDataSource.snapshot()
                snapshot.deleteItems([.bottomLoader])
                diffableDataSource.apply(snapshot)
            }
        }
    }
}
