//
//  SearchViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation
import GameplayKit
import MastodonSDK
import OSLog
import UIKit

final class SearchViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    let searchText = CurrentValueSubject<String, Never>("")
    let searchScope = CurrentValueSubject<String, Never>("")
    
    let isSearching = CurrentValueSubject<Bool, Never>(false)
    
    let searchResult = CurrentValueSubject<Mastodon.Entity.SearchResult?, Never>(nil)
    
    var recommendHashTags = [Mastodon.Entity.Tag]()
    var recommendAccounts = [Mastodon.Entity.Account]()
    
    var hashTagDiffableDataSource: UICollectionViewDiffableDataSource<RecommendHashTagSection, Mastodon.Entity.Tag>?
    var accountDiffableDataSource: UICollectionViewDiffableDataSource<RecommendAccountSection, Mastodon.Entity.Account>?
    var searchResultDiffableDataSource: UITableViewDiffableDataSource<SearchResultSection, SearchResultItem>?

    // bottom loader
    private(set) lazy var loadoldestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadOldestState.Initial(viewModel: self),
            LoadOldestState.Loading(viewModel: self),
            LoadOldestState.Fail(viewModel: self),
            LoadOldestState.Idle(viewModel: self),
            LoadOldestState.NoMore(viewModel: self),
        ])
        stateMachine.enter(LoadOldestState.Initial.self)
        return stateMachine
    }()

    lazy var loadOldestStateMachinePublisher = CurrentValueSubject<LoadOldestState?, Never>(nil)
    
    init(context: AppContext) {
        self.context = context
        guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        Publishers.CombineLatest(
            searchText
                .filter { !$0.isEmpty }
                .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).removeDuplicates(),
            searchScope)
            .flatMap { (text, scope) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> in
                let query = Mastodon.API.Search.Query(accountID: nil,
                                                      maxID: nil,
                                                      minID: nil,
                                                      type: scope,
                                                      excludeUnreviewed: nil,
                                                      q: text,
                                                      resolve: nil,
                                                      limit: nil,
                                                      offset: nil,
                                                      following: nil)
                return context.apiService.search(domain: activeMastodonAuthenticationBox.domain, query: query, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
            }
            .sink { _ in
            } receiveValue: { [weak self] result in
                self?.searchResult.value = result.value
            }
            .store(in: &disposeBag)
        
        isSearching
            .sink { [weak self] isSearching in
                if !isSearching {
                    self?.searchResult.value = nil
                }
            }
            .store(in: &disposeBag)
        
        requestRecommendHashTags()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.recommendHashTags.isEmpty {
                    guard let dataSource = self.hashTagDiffableDataSource else { return }
                    var snapshot = NSDiffableDataSourceSnapshot<RecommendHashTagSection, Mastodon.Entity.Tag>()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(self.recommendHashTags, toSection: .main)
                    dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
        
        requestRecommendAccounts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.recommendAccounts.isEmpty {
                    guard let dataSource = self.accountDiffableDataSource else { return }
                    var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, Mastodon.Entity.Account>()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(self.recommendAccounts, toSection: .main)
                    dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
        
        searchResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchResult in
                guard let self = self else { return }
                guard let dataSource = self.searchResultDiffableDataSource else { return }
                var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
                if let accounts = searchResult?.accounts {
                    snapshot.appendSections([.account])
                    let items = accounts.compactMap { SearchResultItem.account(account: $0) }
                    snapshot.appendItems(items, toSection: .account)
                    if self.searchScope.value == Mastodon.API.Search.Scope.accounts.rawValue {
                        snapshot.appendItems([.bottomLoader], toSection: .account)
                    }
                }
                if let tags = searchResult?.hashtags {
                    snapshot.appendSections([.hashTag])
                    let items = tags.compactMap { SearchResultItem.hashTag(tag: $0) }
                    snapshot.appendItems(items, toSection: .hashTag)
                    if self.searchScope.value == Mastodon.API.Search.Scope.hashTags.rawValue {
                        snapshot.appendItems([.bottomLoader], toSection: .hashTag)
                    }
                }
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
            }
            .store(in: &disposeBag)
    }
    
    func requestRecommendHashTags() -> Future<Void, Error> {
        Future { promise in
            guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                promise(.failure(APIService.APIError.implicit(APIService.APIError.ErrorReason.authenticationMissing)))
                return
            }
            self.context.apiService.recommendTrends(domain: activeMastodonAuthenticationBox.domain, query: nil)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        promise(.failure(error))
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request success", (#file as NSString).lastPathComponent, #line, #function)
                        promise(.success(()))
                    }
                } receiveValue: { [weak self] tags in
                    guard let self = self else { return }
                    self.recommendHashTags = tags.value
                }
                .store(in: &self.disposeBag)
        }
    }

    func requestRecommendAccounts() -> Future<Void, Error> {
        Future { promise in
            guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                promise(.failure(APIService.APIError.implicit(APIService.APIError.ErrorReason.authenticationMissing)))
                return
            }
            self.context.apiService.recommendAccount(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        promise(.failure(error))
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request success", (#file as NSString).lastPathComponent, #line, #function)
                        promise(.success(()))
                    }
                } receiveValue: { [weak self] accounts in
                    guard let self = self else { return }
                    self.recommendAccounts = accounts.value
                }
                .store(in: &self.disposeBag)
        }
    }
}
