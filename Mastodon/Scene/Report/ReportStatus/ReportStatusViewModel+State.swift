//
//  ReportViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import func QuartzCore.CACurrentMediaTime
import Foundation
import GameplayKit
import MastodonSDK

extension ReportStatusViewModel {
    class State: GKState {
        
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        
        weak var viewModel: ReportStatusViewModel?
        
        init(viewModel: ReportStatusViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension ReportStatusViewModel.State {
    class Initial: ReportStatusViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let _ = viewModel else { return false }
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Loading: ReportStatusViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            case is NoMore.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel else { return }
            
            let maxID = viewModel.records.last?.id
            
            Task {
                let managedObjectContext = viewModel.context.managedObjectContext
                let _userID: Mastodon.Entity.Account.ID? = viewModel.user.id
                guard let userID = _userID else {
                    await enter(state: Fail.self)
                    return
                }

                do {
                    let response = try await viewModel.context.apiService.userTimeline(
                        accountID: userID,
                        maxID: maxID,
                        sinceID: nil,
                        excludeReplies: true,
                        excludeReblogs: true,
                        onlyMedia: false,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    var hasNewStatusesAppend = false
                    var newRecords = viewModel.records
                    for status in response.value {
                        guard !newRecords.contains(where: { $0.id == status.id }) else { continue }
                        newRecords.append(status)
                        hasNewStatusesAppend = true
                    }
                    
                    if hasNewStatusesAppend {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    viewModel.records = newRecords

                } catch {
                    await enter(state: Fail.self)
                }
            }
        }
    }
    
    class Fail: ReportStatusViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Idle: ReportStatusViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class NoMore: ReportStatusViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let _ = stateMachine else { return }
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
