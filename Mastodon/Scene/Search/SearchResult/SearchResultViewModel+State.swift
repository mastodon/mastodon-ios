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

extension SearchResultViewModel {
    class State: GKState {
        weak var viewModel: SearchResultViewModel?

        init(viewModel: SearchResultViewModel) {
            self.viewModel = viewModel
        }

        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", (#file as NSString).lastPathComponent, #line, #function, debugDescription, previousState.debugDescription)
//            viewModel?.loadOldestStateMachinePublisher.send(self)
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
        let logger = Logger(subsystem: "SearchResultViewModel.State.Loading", category: "Logic")

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
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }

            if previousState is Initial {
                // trigger bottom loader display
                viewModel.items.value = viewModel.items.value
            }

            let domain = activeMastodonAuthenticationBox.domain

            let searchText = viewModel.searchText.value
            let searchType = viewModel.searchScope.searchType

            guard !searchText.isEmpty else {
                stateMachine.enter(Fail.self)
                return
            }

            if searchText != previousSearchText {
                previousSearchText = searchText
                offset = nil
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
                resolve: nil,
                limit: nil,
                offset: _offset,
                following: nil
            )

            let id = UUID()
            latestLoadingToken = id

            viewModel.context.apiService.search(
                domain: domain,
                query: query,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox
            )
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search \(searchText) fail: \(error.localizedDescription)")
                    stateMachine.enter(Fail.self)
                case .finished:
                    self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search \(searchText) success")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }

                // discard result when search text is outdated
                guard searchText == self.previousSearchText else { return }
                // discard result when request not the latest one
                guard id == self.latestLoadingToken else { return }
                // discard result when state is not Loading
                guard stateMachine.currentState is Loading else { return }

                let oldItems = _offset == nil ? [] : viewModel.items.value
                var newItems: [SearchResultItem] = []

                for account in response.value.accounts {
                    let item = SearchResultItem.account(account: account)
                    guard !oldItems.contains(item) else { continue }
                    newItems.append(item)
                }
                for hashtag in response.value.hashtags {
                    let item = SearchResultItem.hashtag(tag: hashtag)
                    guard !oldItems.contains(item) else { continue }
                    newItems.append(item)
                }

                var newStatusIDs = _offset == nil ? [] : viewModel.statusFetchedResultsController.statusIDs.value
                for status in response.value.statuses {
                    guard !newStatusIDs.contains(status.id) else { continue }
                    newStatusIDs.append(status.id)
                }

                if viewModel.searchScope == .all {
                    stateMachine.enter(NoMore.self)
                } else {
                    stateMachine.enter(Idle.self)
                }
                viewModel.items.value = oldItems + newItems
                viewModel.statusFetchedResultsController.statusIDs.value = newStatusIDs
            }
            .store(in: &viewModel.disposeBag)
        }
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
