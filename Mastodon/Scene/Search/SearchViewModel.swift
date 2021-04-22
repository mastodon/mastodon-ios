//
//  SearchViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import GameplayKit
import MastodonSDK
import OSLog
import UIKit

final class SearchViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    weak var coordinator: SceneCoordinator!
    
    let mastodonUser = CurrentValueSubject<MastodonUser?, Never>(nil)
    let currentMastodonUser = CurrentValueSubject<MastodonUser?, Never>(nil)
    
    // output
    let searchText = CurrentValueSubject<String, Never>("")
    let searchScope = CurrentValueSubject<Mastodon.API.V2.Search.SearchType, Never>(Mastodon.API.V2.Search.SearchType.default)
    
    let isSearching = CurrentValueSubject<Bool, Never>(false)
    
    let searchResult = CurrentValueSubject<Mastodon.Entity.SearchResult?, Never>(nil)
    
    var recommendHashTags = [Mastodon.Entity.Tag]()
    var recommendAccounts = [NSManagedObjectID]()
    var recommendAccountsFallback = PassthroughSubject<Void, Never>()
    
    var hashtagDiffableDataSource: UICollectionViewDiffableDataSource<RecommendHashTagSection, Mastodon.Entity.Tag>?
    var accountDiffableDataSource: UICollectionViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID>?
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
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.coordinator = coordinator
        self.context = context
        super.init()
        
        guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        
        // bind active authentication
        context.authenticationService.activeMastodonAuthentication
            .sink { [weak self] activeMastodonAuthentication in
                guard let self = self else { return }
                guard let activeMastodonAuthentication = activeMastodonAuthentication else {
                    self.currentMastodonUser.value = nil
                    return
                }
                self.currentMastodonUser.value = activeMastodonAuthentication.user
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            searchText
                .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).removeDuplicates(),
            searchScope
        )
        .filter { text, _ in
            !text.isEmpty
        }
        .flatMap { (text, scope) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> in
            
            let query = Mastodon.API.V2.Search.Query(q: text,
                                                     type: scope,
                                                     accountID: nil,
                                                     maxID: nil,
                                                     minID: nil,
                                                     excludeUnreviewed: nil,
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
                    self?.searchText.value = ""
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            isSearching,
            searchText,
            searchScope
        )
        .filter { isSearching, _, _ in
            isSearching
        }
        .sink { [weak self] _, text, scope in
            guard text.isEmpty else { return }
            guard let self = self else { return }
            guard let searchHistories = self.fetchSearchHistory() else { return }
            guard let dataSource = self.searchResultDiffableDataSource else { return }
            var snapshot = NSDiffableDataSourceSnapshot<SearchResultSection, SearchResultItem>()
            snapshot.appendSections([.mixed])
            
            searchHistories.forEach { searchHistory in
                let containsAccount = scope == Mastodon.API.V2.Search.SearchType.accounts || scope == Mastodon.API.V2.Search.SearchType.default
                let containsHashTag = scope == Mastodon.API.V2.Search.SearchType.hashtags || scope == Mastodon.API.V2.Search.SearchType.default
                if let mastodonUser = searchHistory.account, containsAccount {
                    let item = SearchResultItem.accountObjectID(accountObjectID: mastodonUser.objectID)
                    snapshot.appendItems([item], toSection: .mixed)
                }
                if let tag = searchHistory.hashtag, containsHashTag {
                    let item = SearchResultItem.hashtagObjectID(hashtagObjectID: tag.objectID)
                    snapshot.appendItems([item], toSection: .mixed)
                }
            }
            dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
        .store(in: &disposeBag)
        
        requestRecommendHashTags()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.recommendHashTags.isEmpty {
                    guard let dataSource = self.hashtagDiffableDataSource else { return }
                    var snapshot = NSDiffableDataSourceSnapshot<RecommendHashTagSection, Mastodon.Entity.Tag>()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(self.recommendHashTags, toSection: .main)
                    dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
        
        requestRecommendAccountsV2()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.recommendAccounts.isEmpty {
                    self.applyDataSource()
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
        
        recommendAccountsFallback
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.requestRecommendAccounts()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        guard let self = self else { return }
                        if !self.recommendAccounts.isEmpty {
                            self.applyDataSource()
                        }
                    } receiveValue: { _ in
                    }
                    .store(in: &self.disposeBag)
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
                    if self.searchScope.value == Mastodon.API.V2.Search.SearchType.accounts, !items.isEmpty {
                        snapshot.appendItems([.bottomLoader], toSection: .account)
                    }
                }
                if let tags = searchResult?.hashtags {
                    snapshot.appendSections([.hashtag])
                    let items = tags.compactMap { SearchResultItem.hashtag(tag: $0) }
                    snapshot.appendItems(items, toSection: .hashtag)
                    if self.searchScope.value == Mastodon.API.V2.Search.SearchType.hashtags, !items.isEmpty {
                        snapshot.appendItems([.bottomLoader], toSection: .hashtag)
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

    func requestRecommendAccountsV2() -> Future<Void, Error> {
        Future { promise in
            guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                promise(.failure(APIService.APIError.implicit(APIService.APIError.ErrorReason.authenticationMissing)))
                return
            }
            self.context.apiService.suggestionAccountV2(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        if let apiError = error as? Mastodon.API.Error {
                            if apiError.httpResponseStatus == .notFound {
                                self?.recommendAccountsFallback.send()
                            }
                        }
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendAccount request fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        promise(.failure(error))
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendAccount request success", (#file as NSString).lastPathComponent, #line, #function)
                        promise(.success(()))
                    }
                } receiveValue: { [weak self] accounts in
                    guard let self = self else { return }
                    let ids = accounts.value.compactMap({$0.account.id})
                    self.receiveAccounts(ids: ids)
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
            self.context.apiService.suggestionAccount(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendAccount request fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        promise(.failure(error))
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendAccount request success", (#file as NSString).lastPathComponent, #line, #function)
                        promise(.success(()))
                    }
                } receiveValue: { [weak self] accounts in
                    guard let self = self else { return }
                    let ids = accounts.value.compactMap({$0.id})
                    self.receiveAccounts(ids: ids)
                }
                .store(in: &self.disposeBag)
        }
    }
    
    func applyDataSource() {
        guard let dataSource = accountDiffableDataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, NSManagedObjectID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(recommendAccounts, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }
    
    func receiveAccounts(ids: [String]) {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let userFetchRequest = MastodonUser.sortedFetchRequest
        userFetchRequest.predicate = MastodonUser.predicate(domain: activeMastodonAuthenticationBox.domain, ids: ids)
        let mastodonUsers: [MastodonUser]? = {
            let userFetchRequest = MastodonUser.sortedFetchRequest
            userFetchRequest.predicate = MastodonUser.predicate(domain: activeMastodonAuthenticationBox.domain, ids: ids)
            userFetchRequest.returnsObjectsAsFaults = false
            do {
                return try self.context.managedObjectContext.fetch(userFetchRequest)
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        if let users = mastodonUsers {
            let sortedUsers = users.sorted { (user1, user2) -> Bool in
                (ids.firstIndex(of: user1.id) ?? 0) < (ids.firstIndex(of: user2.id) ?? 0)
            }
            recommendAccounts = sortedUsers.map(\.objectID)
        }
    }

    func accountCollectionViewItemDidSelected(mastodonUser: MastodonUser, from: UIViewController) {
        let viewModel = ProfileViewModel(context: context, optionalMastodonUser: mastodonUser)
        DispatchQueue.main.async {
            self.coordinator.present(scene: .profile(viewModel: viewModel), from: from, transition: .show)
        }
    }
    
    func hashtagCollectionViewItemDidSelected(hashtag: Mastodon.Entity.Tag, from: UIViewController) {
        let (tagInCoreData, _) = APIService.CoreData.createOrMergeTag(into: context.managedObjectContext, entity: hashtag)
        let viewModel = HashtagTimelineViewModel(context: context, hashtag: tagInCoreData.name)
        DispatchQueue.main.async {
            self.coordinator.present(scene: .hashtagTimeline(viewModel: viewModel), from: from, transition: .show)
        }
    }
    
    func searchResultItemDidSelected(item: SearchResultItem, from: UIViewController) {
        let searchHistories = fetchSearchHistory()
        _ = context.managedObjectContext.performChanges { [weak self] in
            guard let self = self else { return }
            switch item {
            case .account(let account):
                guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                    return
                }
                // load request mastodon user
                let requestMastodonUser: MastodonUser? = {
                    let request = MastodonUser.sortedFetchRequest
                    request.predicate = MastodonUser.predicate(domain: activeMastodonAuthenticationBox.domain, id: activeMastodonAuthenticationBox.userID)
                    request.fetchLimit = 1
                    request.returnsObjectsAsFaults = false
                    do {
                        return try self.context.managedObjectContext.fetch(request).first
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return nil
                    }
                }()
                let (mastodonUser, _) = APIService.CoreData.createOrMergeMastodonUser(into: self.context.managedObjectContext, for: requestMastodonUser, in: activeMastodonAuthenticationBox.domain, entity: account, userCache: nil, networkDate: Date(), log: OSLog.api)
                if let searchHistories = searchHistories {
                    let history = searchHistories.first { history -> Bool in
                        guard let account = history.account else { return false }
                        return account.objectID == mastodonUser.objectID
                    }
                    if let history = history {
                        history.update(updatedAt: Date())
                    } else {
                        SearchHistory.insert(into: self.context.managedObjectContext, account: mastodonUser)
                    }
                } else {
                    SearchHistory.insert(into: self.context.managedObjectContext, account: mastodonUser)
                }
                let viewModel = ProfileViewModel(context: self.context, optionalMastodonUser: mastodonUser)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .profile(viewModel: viewModel), from: from, transition: .show)
                }
            
            case .hashtag(let tag):
                let (tagInCoreData, _) = APIService.CoreData.createOrMergeTag(into: self.context.managedObjectContext, entity: tag)
                if let searchHistories = searchHistories {
                    let history = searchHistories.first { history -> Bool in
                        guard let hashtag = history.hashtag else { return false }
                        return hashtag.objectID == tagInCoreData.objectID
                    }
                    if let history = history {
                        history.update(updatedAt: Date())
                    } else {
                        SearchHistory.insert(into: self.context.managedObjectContext, hashtag: tagInCoreData)
                    }
                } else {
                    SearchHistory.insert(into: self.context.managedObjectContext, hashtag: tagInCoreData)
                }
                let viewModel = HashtagTimelineViewModel(context: self.context, hashtag: tagInCoreData.name)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .hashtagTimeline(viewModel: viewModel), from: from, transition: .show)
                }
            case .accountObjectID(let accountObjectID):
                if let searchHistories = searchHistories {
                    let history = searchHistories.first { history -> Bool in
                        guard let account = history.account else { return false }
                        return account.objectID == accountObjectID
                    }
                    if let history = history {
                        history.update(updatedAt: Date())
                    }
                }
                let mastodonUser = self.context.managedObjectContext.object(with: accountObjectID) as! MastodonUser
                let viewModel = ProfileViewModel(context: self.context, optionalMastodonUser: mastodonUser)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .profile(viewModel: viewModel), from: from, transition: .show)
                }
            case .hashtagObjectID(let hashtagObjectID):
                if let searchHistories = searchHistories {
                    let history = searchHistories.first { history -> Bool in
                        guard let hashtag = history.hashtag else { return false }
                        return hashtag.objectID == hashtagObjectID
                    }
                    if let history = history {
                        history.update(updatedAt: Date())
                    }
                }
                let tagInCoreData = self.context.managedObjectContext.object(with: hashtagObjectID) as! Tag
                let viewModel = HashtagTimelineViewModel(context: self.context, hashtag: tagInCoreData.name)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .hashtagTimeline(viewModel: viewModel), from: from, transition: .show)
                }
            default:
                break
            }
        }
    }
    
    func fetchSearchHistory() -> [SearchHistory]? {
        let searchHistory: [SearchHistory]? = {
            let request = SearchHistory.sortedFetchRequest
            request.predicate = nil
            request.returnsObjectsAsFaults = false
            do {
                return try context.managedObjectContext.fetch(request)
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
            
        }()
        return searchHistory
    }
    
    func deleteSearchHistory() {
        let result = fetchSearchHistory()
        _ = context.managedObjectContext.performChanges { [weak self] in
            result?.forEach { history in
                self?.context.managedObjectContext.delete(history)
            }
            self?.isSearching.value = true
        }
    }
}
