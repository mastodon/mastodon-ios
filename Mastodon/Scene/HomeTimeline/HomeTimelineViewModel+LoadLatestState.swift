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
            let latestFeedRecords = viewModel.dataController.records

            let latestStatusIDs: [Status.ID] = latestFeedRecords.compactMap { record in
                return record.status?.reblog?.id ?? record.status?.id
            }

            do {
                await AuthenticationServiceProvider.shared.fetchAccounts(apiService: viewModel.context.apiService)
                let response: Mastodon.Response.Content<[Mastodon.Entity.Status]>
                
                /// To find out wether or not we need to show the "Load More" button
                /// we have make sure to eventually overlap with the most recent cached item
                let sinceID = latestFeedRecords.count > 1 ? latestFeedRecords[1].id : nil
                
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
                case let .list(id):
                    response = try await viewModel.context.apiService.listTimeline(
                        id: id,
                        query: .init(sinceID: sinceID),
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                case let .hashtag(tag):
                    response = try await viewModel.context.apiService.hashtagTimeline(
                        hashtag: tag,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                }

                enter(state: Idle.self)
                viewModel.receiveLoadingStateCompletion(.finished)

                let statuses = response.value

                if statuses.isEmpty {
                    // stop refresher if no new statuses
                    viewModel.dataController.records = []
                    viewModel.didLoadLatest.send()
                } else {
                    var toAdd = [MastodonFeed]()
                    
                    let last = statuses.last
                    if let latestFirstId = latestFeedRecords.first?.id, let last, last.id == latestFirstId {
                        /// We have an overlap with the existing Statuses, thus no _Load More_ required
                        toAdd = statuses.prefix(statuses.count-1).map({ MastodonFeed.fromStatus($0.asMastodonStatus, kind: .home) })
                    } else {
                        /// If we do not have existing items, no _Load More_ is required as there is no gap
                        /// If our fetched Statuses do **not** overlap with the existing ones, we need a _Load More_ Button
                        toAdd = statuses.map({ MastodonFeed.fromStatus($0.asMastodonStatus, kind: .home) })
                        toAdd.last?.hasMore = latestFeedRecords.isNotEmpty
                    }
                    
                    viewModel.dataController.records = (toAdd + latestFeedRecords).removingDuplicates()
                }
                viewModel.timelineIsEmpty.value = latestStatusIDs.isEmpty && statuses.isEmpty
                
                if !isUserInitiated {
                    FeedbackGenerator.shared.generate(.impact(.light))
                }
                
                let hasNewStatuses: Bool = {
                    if sinceID != nil {
                        return statuses.count > 1
                    }
                    return statuses.isNotEmpty
                }()
                
                if hasNewStatuses && (previousState is HomeTimelineViewModel.LoadLatestState.ContextSwitch) == false {
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
