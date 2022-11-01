//
//  SearchResultViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK
import MastodonCore

extension SearchResultViewModel {
    class State: GKState {
        
        let logger = Logger(subsystem: "SearchResultViewModel.State", category: "StateMachine")
        
        let id = UUID()

        weak var viewModel: SearchResultViewModel?

        init(viewModel: SearchResultViewModel) {
            self.viewModel = viewModel
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            let from = previousState.flatMap { String(describing: $0) } ?? "nil"
            let to = String(describing: self)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(from) -> \(to)")
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(String(describing: self))")
        }
    }
}

extension SearchResultViewModel.State {
    class Initial: SearchResultViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self && !viewModel.searchText.value.isEmpty
        }
    }

    class Loading: SearchResultViewModel.State {

        var previousSearchText = ""
        var offset: Int? = nil
        var latestLoadingToken = UUID()

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = self.viewModel else { return false }
            switch stateClass {
            case is Fail.Type, is Idle.Type, is NoMore.Type:
                return true
            case is Loading.Type:
                return viewModel.searchText.value != previousSearchText
            default:
                return false
            }
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }

            let searchText = viewModel.searchText.value
            let searchType = viewModel.searchScope.searchType

            if previousState is NoMore && previousSearchText == searchText {
                // same searchText from NoMore
                // break the loading and resume NoMore state
                stateMachine.enter(NoMore.self)
                return
            } else {
                // trigger bottom loader display
//                viewModel.items.value = viewModel.items.value
            }

            guard !searchText.isEmpty else {
                stateMachine.enter(Fail.self)
                return
            }

            if searchText != previousSearchText {
                previousSearchText = searchText
                offset = nil
            } else {
                offset = viewModel.items.count
            }

            // not set offset for all case
            // and assert other cases the items are all the same type elements
            let _offset: Int? = {
                switch searchType {
                case .default:  return nil
                default:        return offset
                }
            }()

            let query = Mastodon.API.V2.Search.Query(
                q: searchText,
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
                    
                    // discard result when search text is outdated
                    guard searchText == self.previousSearchText else { return }
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
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search \(searchText) fail: \(error.localizedDescription)")
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
