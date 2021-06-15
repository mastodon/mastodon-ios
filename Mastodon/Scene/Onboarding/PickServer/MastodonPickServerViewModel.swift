//
//  MastodonPickServerViewModel.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import os.log
import UIKit
import Combine
import GameplayKit
import MastodonSDK
import CoreDataStack

class MastodonPickServerViewModel: NSObject {
    
    enum PickServerMode {
        case signUp
        case signIn
    }
    
    enum EmptyStateViewState {
        case none
        case loading
        case badNetwork
    }
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let mode: PickServerMode
    let context: AppContext
    var categoryPickerItems: [CategoryPickerItem] = {
        var items: [CategoryPickerItem] = []
        items.append(.all)
        items.append(contentsOf: APIService.stubCategories().map { CategoryPickerItem.category(category: $0) })
        return items
    }()
    let selectCategoryItem = CurrentValueSubject<CategoryPickerItem, Never>(.all)
    let searchText = CurrentValueSubject<String, Never>("")
    let indexedServers = CurrentValueSubject<[Mastodon.Entity.Server], Never>([])
    let unindexedServers = CurrentValueSubject<[Mastodon.Entity.Server]?, Never>([])    // set nil when loading
    let viewWillAppear = PassthroughSubject<Void, Never>()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<PickServerSection, PickServerItem>?
    private(set) lazy var loadIndexedServerStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadIndexedServerState.Initial(viewModel: self),
            LoadIndexedServerState.Loading(viewModel: self),
            LoadIndexedServerState.Fail(viewModel: self),
            LoadIndexedServerState.Idle(viewModel: self),
        ])
        stateMachine.enter(LoadIndexedServerState.Initial.self)
        return stateMachine
    }()
    let filteredIndexedServers = CurrentValueSubject<[Mastodon.Entity.Server], Never>([])
    let servers = CurrentValueSubject<[Mastodon.Entity.Server], Error>([])
    let selectedServer = CurrentValueSubject<Mastodon.Entity.Server?, Never>(nil)
    let error = CurrentValueSubject<Error?, Never>(nil)

    let isLoadingIndexedServers = CurrentValueSubject<Bool, Never>(false)
    let emptyStateViewState = CurrentValueSubject<EmptyStateViewState, Never>(.none)
        
    init(context: AppContext, mode: PickServerMode) {
        self.context = context
        self.mode = mode
        super.init()
        
        configure()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonPickServerViewModel {
    
    private func configure() {
        Publishers.CombineLatest(
            filteredIndexedServers,
            unindexedServers
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] indexedServers, unindexedServers in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }
            
            let oldSnapshot = diffableDataSource.snapshot()
            var oldSnapshotServerItemAttributeDict: [String : PickServerItem.ServerItemAttribute] = [:]
            for item in oldSnapshot.itemIdentifiers {
                guard case let .server(server, attribute) = item else { continue }
                oldSnapshotServerItemAttributeDict[server.domain] = attribute
            }
            
            var snapshot = NSDiffableDataSourceSnapshot<PickServerSection, PickServerItem>()
            snapshot.appendSections([.header, .category, .search, .servers])
            snapshot.appendItems([.header], toSection: .header)
            snapshot.appendItems([.categoryPicker(items: self.categoryPickerItems)], toSection: .category)
            snapshot.appendItems([.search], toSection: .search)
            // TODO: handle filter
            var serverItems: [PickServerItem] = []
            for server in indexedServers {
                let attribute = oldSnapshotServerItemAttributeDict[server.domain] ?? PickServerItem.ServerItemAttribute(isLast: false, isExpand: false)
                attribute.isLast.value = false
                let item = PickServerItem.server(server: server, attribute: attribute)
                guard !serverItems.contains(item) else { continue }
                serverItems.append(item)
            }
            
            if let unindexedServers = unindexedServers {
                if !unindexedServers.isEmpty {
                    for server in unindexedServers {
                        let attribute = oldSnapshotServerItemAttributeDict[server.domain] ?? PickServerItem.ServerItemAttribute(isLast: false, isExpand: false)
                        attribute.isLast.value = false
                        let item = PickServerItem.server(server: server, attribute: attribute)
                        guard !serverItems.contains(item) else { continue }
                        serverItems.append(item)
                    }
                } else {
                    if indexedServers.isEmpty && !self.isLoadingIndexedServers.value {
                        serverItems.append(.loader(attribute: PickServerItem.LoaderItemAttribute(isLast: false, isEmptyResult: true)))
                    }
                }
            } else {
                serverItems.append(.loader(attribute: PickServerItem.LoaderItemAttribute(isLast: false, isEmptyResult: false)))
            }
            
            if case let .server(_, attribute) = serverItems.last {
                attribute.isLast.value = true
            }
            if case let .loader(attribute) = serverItems.last {
                attribute.isLast = true
            }
            snapshot.appendItems(serverItems, toSection: .servers)
            
            diffableDataSource.defaultRowAnimation = .fade
            diffableDataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        })
        .store(in: &disposeBag)
        
        isLoadingIndexedServers
            .map { isLoadingIndexedServers -> EmptyStateViewState in
                if isLoadingIndexedServers {
                    return .loading
                } else {
                    return .none
                }
            }
            .assign(to: \.value, on: emptyStateViewState)
            .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            indexedServers.eraseToAnyPublisher(),
            selectCategoryItem.eraseToAnyPublisher(),
            searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).removeDuplicates()
        )
        .map { indexedServers, selectCategoryItem, searchText -> [Mastodon.Entity.Server] in
            // Filter the indexed servers from joinmastodon.org
            switch selectCategoryItem {
            case .all:
                return MastodonPickServerViewModel.filterServers(servers: indexedServers, category: nil, searchText: searchText)
            case .category(let category):
                return MastodonPickServerViewModel.filterServers(servers: indexedServers, category: category.category.rawValue, searchText: searchText)
            }
        }
        .assign(to: \.value, on: filteredIndexedServers)
        .store(in: &disposeBag)
        
        searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { [weak self] searchText -> AnyPublisher<Result<Mastodon.Response.Content<[Mastodon.Entity.Server]>, Error>, Never>? in
                // Check if searchText is a valid mastodon server domain
                guard let self = self else { return nil }
                guard let domain = AuthenticationViewModel.parseDomain(from: searchText) else {
                    return Just(Result.failure(APIService.APIError.implicit(.badRequest))).eraseToAnyPublisher()
                }
                self.unindexedServers.value = nil
                return self.context.apiService.instance(domain: domain)
                    .map { response -> Result<Mastodon.Response.Content<[Mastodon.Entity.Server]>, Error>in
                        let newResponse = response.map { [Mastodon.Entity.Server(instance: $0)] }
                        return Result.success(newResponse)
                    }
                    .catch { error in
                        return Just(Result.failure(error))
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveValue: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.unindexedServers.send(response.value)
                case .failure(let error):
                    if let error = error as? APIService.APIError,
                       case let .implicit(reason) = error,
                       case .badRequest = reason {
                        self.unindexedServers.send([])
                    } else {
                        self.unindexedServers.send(nil)
                    }
                }
            })
            .store(in: &disposeBag)
    }

}
   
extension MastodonPickServerViewModel {
    private static func filterServers(servers: [Mastodon.Entity.Server], category: String?, searchText: String) -> [Mastodon.Entity.Server] {
        return servers
            // 1. Filter the category
            .filter {
                guard let category = category else  { return true }
                return $0.category.caseInsensitiveCompare(category) == .orderedSame
            }
            // 2. Filter the searchText
            .filter {
                let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !searchText.isEmpty else {
                    return true
                }
                return $0.domain.lowercased().contains(searchText.lowercased())
            }
    }
}

// MARK: - SignUp methods & structs
extension MastodonPickServerViewModel {
    struct SignUpResponseFirst {
        let instance: Mastodon.Response.Content<Mastodon.Entity.Instance>
        let application: Mastodon.Response.Content<Mastodon.Entity.Application>
    }
    
    struct SignUpResponseSecond {
        let instance: Mastodon.Response.Content<Mastodon.Entity.Instance>
        let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    }
    
    struct SignUpResponseThird {
        let instance: Mastodon.Response.Content<Mastodon.Entity.Instance>
        let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
        let applicationToken: Mastodon.Response.Content<Mastodon.Entity.Token>
    }
}
