//
//  HomeTimelineViewModel+LoadLatestState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import func QuartzCore.CACurrentMediaTime
import Foundation
import CoreData
import CoreDataStack
import GameplayKit
import MastodonCore
import MastodonSDK

extension HomeTimelineViewModel {
    class LoadLatestState: GKState {
        
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        
        weak var viewModel: HomeTimelineViewModel?
        
        init(viewModel: HomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor
        func enter(state: LoadLatestState.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension HomeTimelineViewModel.LoadLatestState {
    class Initial: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == LoadingManually.self
        }
    }
    
    class Loading: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            didEnter(from: previousState, viewModel: viewModel, isUserInitiated: false)
        }
    }
    
    class LoadingManually: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            didEnter(from: previousState, viewModel: viewModel, isUserInitiated: true)
        }
    }
    
    class Fail: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == LoadingManually.self || stateClass == ContextSwitch.self
        }
    }

    class ContextSwitch: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == LoadingManually.self  || stateClass == ContextSwitch.self
        }

        override func didEnter(from previousState: GKState?) {
            guard let viewModel else { return }
            guard let diffableDataSource = viewModel.diffableDataSource else {
                assertionFailure()
                return
            }

            OperationQueue.main.addOperation {
                viewModel.dataController.records = []
                var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems([.topLoader], toSection: .main)
                diffableDataSource.apply(snapshot) { [weak self] in
                    guard let self else { return }

                    self.stateMachine?.enter(Loading.self)
                }
            }
        }
    }

    private func didEnter(from previousState: GKState?, viewModel: HomeTimelineViewModel?, isUserInitiated: Bool) {
        super.didEnter(from: previousState)

        guard let viewModel else { return }


        Task { @MainActor in
            let latestFeedRecords = viewModel.dataController.records.prefix(APIService.onceRequestStatusMaxCount)

            let latestStatusIDs: [Status.ID] = latestFeedRecords.compactMap { record in
                return record.status?.reblog?.id ?? record.status?.id
            }

            do {
                await AuthenticationServiceProvider.shared.fetchAccounts(apiService: viewModel.context.apiService)
                let response: Mastodon.Response.Content<[Mastodon.Entity.Status]>
                
                /// To find out wether or not we need to show the "Load More" button
                /// we have make sure to eventually overlap with the most recent cached item
                let sinceID = latestFeedRecords.count > 1 ? latestFeedRecords[1].id : "1"
                
                switch viewModel.timelineContext {
                case .home:
                    response = try await viewModel.context.apiService.homeTimeline(
                        sinceID: sinceID,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                case .public:
                    response = try await viewModel.context.apiService.publicTimeline(
                        query: .init(local: true, sinceID: sinceID),
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                }

                enter(state: Idle.self)
                viewModel.receiveLoadingStateCompletion(.finished)

                // stop refresher if no new statuses
                let statuses = response.value
                let newStatuses = statuses.filter { status in !latestStatusIDs.contains(where: { $0 == status.reblog?.id || $0 == status.id }) }

                if newStatuses.isEmpty {
                    viewModel.didLoadLatest.send()
                } else {                    
                    viewModel.dataController.records = {
                        var oldRecords = viewModel.dataController.records

                        var newRecords = [MastodonFeed]()
                        
                        /// See HomeTimelineViewModel.swift for the "Load More"-counterpart when fetching new timeline items
                        for (index, status) in newStatuses.enumerated() {
                            if index < newStatuses.count - 1 {
                                newRecords.append(
                                    MastodonFeed.fromStatus(.fromEntity(status), kind: .home, hasMore: false)
                                )
                                continue
                            }
                            
                            let hasMore: Bool = {
                                guard let firstOldEntity = oldRecords.first?.status?.entity else {
                                    return false
                                }
                                return status != firstOldEntity
                            }()

                            newRecords.append(
                                MastodonFeed.fromStatus(.fromEntity(status), kind: .home, hasMore: hasMore)
                            )
                        }
                        for (i, record) in newRecords.enumerated() {
                            if let index = oldRecords.firstIndex(where: { $0.status?.reblog?.id == record.id || $0.status?.id == record.id }) {
                                oldRecords[index] = record
                                if newRecords.count > i {
                                    newRecords.remove(at: i)
                                }
                            }
                        }
                        return (newRecords + oldRecords).removingDuplicates()
                    }()
                }
                viewModel.timelineIsEmpty.value = latestStatusIDs.isEmpty && statuses.isEmpty
                
                if !isUserInitiated {
                    FeedbackGenerator.shared.generate(.impact(.light))
                }

                if newStatuses.isNotEmpty && (previousState is HomeTimelineViewModel.LoadLatestState.ContextSwitch) == false {
                    viewModel.hasNewPosts.value = true
                }

            } catch {
                enter(state: Idle.self)
                viewModel.didLoadLatest.send()
                viewModel.receiveLoadingStateCompletion(.failure(error))
            }
        }   // end Task
    }
}
