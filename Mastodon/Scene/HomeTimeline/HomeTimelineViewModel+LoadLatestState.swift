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
            return stateClass == Loading.self || stateClass == LoadingManually.self
        }
    }

    private func didEnter(from previousState: GKState?, viewModel: HomeTimelineViewModel?, isUserInitiated: Bool) {
        super.didEnter(from: previousState)

        guard let viewModel else { return }
        
        let latestFeedRecords = viewModel.dataController.records.prefix(APIService.onceRequestStatusMaxCount)

        Task {
            let latestStatusIDs: [Status.ID] = latestFeedRecords.compactMap { record in
                return record.status?.reblog?.id ?? record.status?.id
            }

            do {
                await AuthenticationServiceProvider.shared.fetchAccounts(apiService: viewModel.context.apiService)
                let response: Mastodon.Response.Content<[Mastodon.Entity.Status]>

                switch viewModel.timelineContext {
                case .following:
                    response = try await viewModel.context.apiService.homeTimeline(
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                case .localCommunity:
                    response = try await viewModel.context.apiService.publicTimeline(
                        query: .init(local: true),
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                }

                await enter(state: Idle.self)
                viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(.finished)

                // stop refresher if no new statuses
                let statuses = response.value
                let newStatuses = statuses.filter { status in !latestStatusIDs.contains(where: { $0 == status.reblog?.id || $0 == status.id }) }

                if newStatuses.isEmpty {
                    viewModel.didLoadLatest.send()
                } else {
                    if !latestStatusIDs.isEmpty {
                        viewModel.homeTimelineNavigationBarTitleViewModel.newPostsIncoming()
                    }
                    
                    viewModel.dataController.records = {
                        var newRecords: [MastodonFeed] = newStatuses.map {
                            MastodonFeed.fromStatus(.fromEntity($0), kind: .home)
                        }
                        var oldRecords = viewModel.dataController.records
                        for (i, record) in newRecords.enumerated() {
                            if let index = oldRecords.firstIndex(where: { $0.status?.reblog?.id == record.id || $0.status?.id == record.id }) {
                                oldRecords[index] = record
                                if newRecords.count > index {
                                    newRecords.remove(at: i)
                                }
                            }
                        }
                        return (newRecords + oldRecords).removingDuplicates()
                    }()
                }
                viewModel.timelineIsEmpty.value = latestStatusIDs.isEmpty && statuses.isEmpty
                
                if !isUserInitiated {
                    await UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()
                }
                
            } catch {
                await enter(state: Idle.self)
                viewModel.didLoadLatest.send()
                viewModel.homeTimelineNavigationBarTitleViewModel.receiveLoadingStateCompletion(.failure(error))
            }
        }   // end Task
    }
}
