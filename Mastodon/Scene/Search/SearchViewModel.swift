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
    
    let currentMastodonUser = CurrentValueSubject<MastodonUser?, Never>(nil)
    let viewDidAppeared = PassthroughSubject<Void, Never>()
    
    // output
    let searchText = CurrentValueSubject<String, Never>("")
    let searchScope = CurrentValueSubject<Mastodon.API.V2.Search.SearchType, Never>(Mastodon.API.V2.Search.SearchType.default)
    
    let isSearching = CurrentValueSubject<Bool, Never>(false)
    
    let searchResult = CurrentValueSubject<Mastodon.Entity.SearchResult?, Never>(nil)
    
    // var recommendHashTags = [Mastodon.Entity.Tag]()
    var recommendAccounts = [NSManagedObjectID]()
    var recommendAccountsFallback = PassthroughSubject<Void, Never>()
    
    var hashtagDiffableDataSource: UICollectionViewDiffableDataSource<RecommendHashTagSection, Mastodon.Entity.Tag>?
    var accountDiffableDataSource: UICollectionViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID>?
    var searchResultDiffableDataSource: UITableViewDiffableDataSource<SearchResultSection, SearchResultItem>?

    let statusFetchedResultsController: StatusFetchedResultsController

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
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalTweetPredicate: nil
        )
        super.init()

        // bind active authentication
        context.authenticationService.activeMastodonAuthentication
            .sink { [weak self] activeMastodonAuthentication in
                guard let self = self else { return }
                guard let activeMastodonAuthentication = activeMastodonAuthentication else {
                    self.currentMastodonUser.value = nil
                    return
                }
                self.currentMastodonUser.value = activeMastodonAuthentication.user
                self.statusFetchedResultsController.domain.value = activeMastodonAuthentication.domain
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
        .compactMap { (text, scope) -> AnyPublisher<Result<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error>, Never>? in
            guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return nil }
            let query = Mastodon.API.V2.Search.Query(
                q: text,
                type: scope,
                accountID: nil,
                maxID: nil,
                minID: nil,
                excludeUnreviewed: nil,
                resolve: nil,
                limit: nil,
                offset: nil,
                following: nil
            )
            return context.apiService.search(
                domain: activeMastodonAuthenticationBox.domain,
                query: query,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox
            )
            // .retry(3)   // iOS 14.0 SDK may not works here. needs testing before add this
            .map { response in Result<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> { response } }
            .catch { error in Just(Result<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> { throw error }) }
            .eraseToAnyPublisher()
        }
        .switchToLatest()
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard self.isSearching.value else { return }
                self.searchResult.value = response.value
            case .failure(let error):
                break
            }
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

        Publishers.CombineLatest(
            context.authenticationService.activeMastodonAuthenticationBox,
            viewDidAppeared
        )
        .compactMap { activeMastodonAuthenticationBox, _ -> AuthenticationService.MastodonAuthenticationBox? in
            return activeMastodonAuthenticationBox
        }
        .throttle(for: 1, scheduler: DispatchQueue.main, latest: false)
        .flatMap { box in
            context.apiService.recommendTrends(domain: box.domain, query: nil)
                .map { response in Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { response } }
                .catch { error in Just(Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { throw error }) }
                .eraseToAnyPublisher()
        }
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let dataSource = self.hashtagDiffableDataSource else { return }
                var snapshot = NSDiffableDataSourceSnapshot<RecommendHashTagSection, Mastodon.Entity.Tag>()
                snapshot.appendSections([.main])
                snapshot.appendItems(response.value, toSection: .main)
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
            case .failure(let error):
                break
            }
        }
        .store(in: &disposeBag)

        Publishers.CombineLatest(
            context.authenticationService.activeMastodonAuthenticationBox,
            viewDidAppeared
        )
        .compactMap { activeMastodonAuthenticationBox, _ -> AuthenticationService.MastodonAuthenticationBox? in
            return activeMastodonAuthenticationBox
        }
        .throttle(for: 1, scheduler: DispatchQueue.main, latest: false)
        .flatMap { box -> AnyPublisher<Result<[Mastodon.Entity.Account.ID], Error>, Never> in
            context.apiService.suggestionAccountV2(domain: box.domain, query: nil, mastodonAuthenticationBox: box)
                .map { response in Result<[Mastodon.Entity.Account.ID], Error> { response.value.map { $0.account.id } } }
                .catch { error -> AnyPublisher<Result<[Mastodon.Entity.Account.ID], Error>, Never> in
                    if let apiError = error as? Mastodon.API.Error, apiError.httpResponseStatus == .notFound {
                        return context.apiService.suggestionAccount(domain: box.domain, query: nil, mastodonAuthenticationBox: box)
                            .map { response in Result<[Mastodon.Entity.Account.ID], Error> { response.value.map { $0.id } } }
                            .catch { error in Just(Result<[Mastodon.Entity.Account.ID], Error> { throw error }) }
                            .eraseToAnyPublisher()
                    } else {
                        return Just(Result<[Mastodon.Entity.Account.ID], Error> { throw error })
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        }
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userIDs):
                self.receiveAccounts(ids: userIDs)
            case .failure(let error):
                break
            }
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
    
    func receiveAccounts(ids: [Mastodon.Entity.Account.ID]) {
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
        guard let users = mastodonUsers else { return }
        let objectIDs: [NSManagedObjectID] = users
            .compactMap { object in
                ids.firstIndex(of: object.id).map { index in (index, object) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }

        // append at front
        let newObjectIDs = objectIDs.filter { !self.recommendAccounts.contains($0) }
        self.recommendAccounts = newObjectIDs + self.recommendAccounts

        guard let dataSource = self.accountDiffableDataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, NSManagedObjectID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(self.recommendAccounts, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
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
