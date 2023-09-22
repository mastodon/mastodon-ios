//
//  SearchResultViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import Foundation
import GameplayKit
import MastodonSDK
import MastodonCore

extension SearchResultViewModel {
    class State: GKState {
        
        let id = UUID()

        weak var viewModel: SearchResultViewModel?

        init(viewModel: SearchResultViewModel) {
            self.viewModel = viewModel
        }

        @MainActor
        public func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension SearchResultViewModel.State {
    class Initial: SearchResultViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            guard let viewModel else { return }

            viewModel.items = [.bottomLoader(attribute: .init(isEmptyResult: false))]
        }
    }

    class Loading: SearchResultViewModel.State {

        var offset: Int? = nil
        var latestLoadingToken = UUID()

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type, is Idle.Type, is NoMore.Type:
                return true
            default:
                return false
            }
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel, let stateMachine = stateMachine else { return }

            let searchType = viewModel.searchScope.searchType

            if previousState is NoMore {
                // same searchText from NoMore
                // break the loading and resume NoMore state
                stateMachine.enter(NoMore.self)
                return
            } else {
                // trigger bottom loader display
//                viewModel.items.value = viewModel.items.value
            }

            guard viewModel.searchText.isEmpty == false else {
                stateMachine.enter(Fail.self)
                return
            }

            offset = viewModel.items.filter({ item in
                if case .bottomLoader(_) = item {
                    return false
                } else {
                    return true
                }
            }).count

            // not set offset for all case
            // and assert other cases the items are all the same type elements
            let _offset: Int? = {
                switch searchType {
                case .default:  return nil
                default:        return offset
                }
            }()

            let query = Mastodon.API.V2.Search.Query(
                q: viewModel.searchText,
                type: searchType,
                accountID: nil,
                maxID: nil,
                minID: nil,
                excludeUnreviewed: nil,
                resolve: true,
                limit: nil,
                offset: _offset,
                following: nil
            )

            let id = UUID()
            latestLoadingToken = id
            
            Task {
                do {
                    let response = try await viewModel.context.apiService.search(
                        query: query,
                        authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                    )
                    
                    // discard result when request not the latest one
                    guard id == self.latestLoadingToken else { return }
                    // discard result when state is not Loading
                    guard stateMachine.currentState is Loading else { return }

                    let userIDs = response.value.accounts.map { $0.id }
                    let statusIDs = response.value.statuses.map { $0.id }

                    let isNoMore = userIDs.isEmpty && statusIDs.isEmpty

                    if viewModel.searchScope == .all || isNoMore {
                        await enter(state: NoMore.self)
                    } else {
                        await enter(state: Idle.self)
                    }
                    
                    // reset data source when the search is refresh
                    if offset == nil {
                        viewModel.userFetchedResultsController.userIDs = []
                        viewModel.statusFetchedResultsController.statusIDs = []
                        viewModel.hashtags = []
                    }

                    viewModel.userFetchedResultsController.append(userIDs: userIDs)
                    viewModel.statusFetchedResultsController.append(statusIDs: statusIDs)
                    
                    var hashtags = viewModel.hashtags
                    for hashtag in response.value.hashtags where !hashtags.contains(hashtag) {
                        hashtags.append(hashtag)
                    }
                    viewModel.hashtags = hashtags
                    
                } catch {
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }

    class Fail: SearchResultViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }

    class Idle: SearchResultViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }

    class NoMore: SearchResultViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
}
