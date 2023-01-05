//
//  ReportViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import os.log
import func QuartzCore.CACurrentMediaTime
import Foundation
import CoreData
import CoreDataStack
import GameplayKit

extension ReportStatusViewModel {
    class State: GKState {
        
        let logger = Logger(subsystem: "ReportViewModel.State", category: "StateMachine")

        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        
        weak var viewModel: ReportStatusViewModel?
        
        init(viewModel: ReportStatusViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? ReportStatusViewModel.State
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
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
            
            let maxID = viewModel.statusFetchedResultsController.statusIDs.last
            
            Task {
                let managedObjectContext = viewModel.context.managedObjectContext
                let _userID: MastodonUser.ID? = try await managedObjectContext.perform {
                    guard let user = viewModel.user.object(in: managedObjectContext) else { return nil }
                    return user.id
                }
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
                    var statusIDs = viewModel.statusFetchedResultsController.statusIDs
                    for status in response.value {
                        guard !statusIDs.contains(status.id) else { continue }
                        statusIDs.append(status.id)
                        hasNewStatusesAppend = true
                    }
                    
                    if hasNewStatusesAppend {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    viewModel.statusFetchedResultsController.statusIDs = statusIDs

                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch user timeline fail: \(error.localizedDescription)")
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
