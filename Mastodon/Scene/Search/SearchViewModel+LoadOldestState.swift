//
//  SearchViewModel+LoadOldestState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import Foundation
import GameplayKit
import MastodonSDK
import os.log

extension SearchViewModel {
    class LoadOldestState: GKState {
        weak var viewModel: SearchViewModel?
        
        init(viewModel: SearchViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", (#file as NSString).lastPathComponent, #line, #function, debugDescription, previousState.debugDescription)
            viewModel?.loadOldestStateMachinePublisher.send(self)
        }
    }
}

extension SearchViewModel.LoadOldestState {
    class Initial: SearchViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard viewModel.searchResult.value != nil else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: SearchViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }
            guard let oldSearchResult = viewModel.searchResult.value else {
                stateMachine.enter(Fail.self)
                return
            }
            var offset = 0
            switch viewModel.searchScope.value {
            case Mastodon.API.Search.Scope.accounts.rawValue:
                offset = oldSearchResult.accounts.count
            case Mastodon.API.Search.Scope.hashtags.rawValue:
                offset = oldSearchResult.hashtags.count
            default:
                return
            }
            let query = Mastodon.API.Search.Query(accountID: nil,
                                                  maxID: nil,
                                                  minID: nil,
                                                  type: viewModel.searchScope.value,
                                                  excludeUnreviewed: nil,
                                                  q: viewModel.searchText.value,
                                                  resolve: nil,
                                                  limit: nil,
                                                  offset: offset,
                                                  following: nil)
            viewModel.context.apiService.search(domain: activeMastodonAuthenticationBox.domain, query: query, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: load oldest search failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                    case .finished:
                        // handle isFetchingLatestTimeline in fetch controller delegate
                        break
                    }
                } receiveValue: { result in
                    switch viewModel.searchScope.value {
                    case Mastodon.API.Search.Scope.accounts.rawValue:
                        if result.value.accounts.isEmpty {
                            stateMachine.enter(NoMore.self)
                        } else {
                            var newAccounts = [Mastodon.Entity.Account]()
                            newAccounts.append(contentsOf: oldSearchResult.accounts)
                            newAccounts.append(contentsOf: result.value.accounts)
                            viewModel.searchResult.value = Mastodon.Entity.SearchResult(accounts: newAccounts.removeDuplicate(), statuses: oldSearchResult.statuses, hashtags: oldSearchResult.hashtags)
                            stateMachine.enter(Idle.self)
                        }
                    case Mastodon.API.Search.Scope.hashtags.rawValue:
                        if result.value.hashtags.isEmpty {
                            stateMachine.enter(NoMore.self)
                        } else {
                            var newTags = [Mastodon.Entity.Tag]()
                            newTags.append(contentsOf: oldSearchResult.hashtags)
                            newTags.append(contentsOf: result.value.hashtags)
                            viewModel.searchResult.value = Mastodon.Entity.SearchResult(accounts: oldSearchResult.accounts, statuses: oldSearchResult.statuses, hashtags: newTags.removeDuplicate())
                            stateMachine.enter(Idle.self)
                        }
                    default:
                        return
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: SearchViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: SearchViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            stateClass == Loading.self
        }
    }

    class NoMore: SearchViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // reset state if needs
            stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            guard let viewModel = viewModel else { return }
            guard let diffableDataSource = viewModel.searchResultDiffableDataSource else {
                assertionFailure()
                return
            }
            var snapshot = diffableDataSource.snapshot()
            snapshot.deleteItems([.bottomLoader])
            diffableDataSource.apply(snapshot)
        }
    }
}
