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
    let selectCategoryIndex = CurrentValueSubject<Int, Never>(0)
    let searchText = CurrentValueSubject<String?, Never>(nil)
    let indexedServers = CurrentValueSubject<[Mastodon.Entity.Server], Never>([])
    let unindexedServers = CurrentValueSubject<[Mastodon.Entity.Instance], Never>([])
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
    let servers = CurrentValueSubject<[Mastodon.Entity.Server], Error>([])
    let selectedServer = CurrentValueSubject<Mastodon.Entity.Server?, Never>(nil)
    let error = PassthroughSubject<Error, Never>()
    let authenticated = PassthroughSubject<(domain: String, account: Mastodon.Entity.Account), Never>()
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)

    let isLoadingIndexedServers = CurrentValueSubject<Bool, Never>(false)
    let emptyStateViewState = CurrentValueSubject<EmptyStateViewState, Never>(.none)
    
    var mastodonPinBasedAuthenticationViewController: UIViewController?
    
    init(context: AppContext, mode: PickServerMode) {
        self.context = context
        self.mode = mode
        super.init()
        
        configure()
    }
    
    private func configure() {
        Publishers.CombineLatest3(
            indexedServers,
            unindexedServers,
            searchText
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] indexedServers, unindexedServers, searchText in
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
                attribute.isLast = false
                let item = PickServerItem.server(server: server, attribute: attribute)
                serverItems.append(item)
            }
            if case let .server(_, attribute) = serverItems.last {
                attribute.isLast = true
            }
            snapshot.appendItems(serverItems, toSection: .servers)
            
            diffableDataSource.apply(snapshot)
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
        
//        Publishers.CombineLatest3(
//            selectCategoryIndex,
//            searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).removeDuplicates(),
//            indexedServers
//        )
//        .flatMap { [weak self] (selectCategoryIndex, searchText, allServers) -> AnyPublisher<Result<[Mastodon.Entity.Server], Error>, Never> in
//            guard let self = self else { return Just(Result.success([])).eraseToAnyPublisher() }
//
//            // 1. Search from the servers recorded in joinmastodon.org
//            let searchedServersFromAPI = self.searchServersFromAPI(category: self.categories[selectCategoryIndex], searchText: searchText, allServers: allServers)
//            if !searchedServersFromAPI.isEmpty {
//                // If found servers, just return
//                return Just(Result.success(searchedServersFromAPI)).eraseToAnyPublisher()
//            }
//            // 2. No server found in the recorded list, check if searchText is a valid mastodon server domain
//            if let toSearchText = searchText, !toSearchText.isEmpty, let _ = URL(string: "https://\(toSearchText)") {
//                return self.context.apiService.instance(domain: toSearchText)
//                    .map { return Result.success([Mastodon.Entity.Server(instance: $0.value)]) }
//                    .catch({ error -> Just<Result<[Mastodon.Entity.Server], Error>> in
//                        return Just(Result.failure(error))
//                    })
//                    .eraseToAnyPublisher()
//            }
//            return Just(Result.success(searchedServersFromAPI)).eraseToAnyPublisher()
//        }
//        .sink { _ in
//
//        } receiveValue: { [weak self] result in
//            switch result {
//            case .success(let servers):
//                self?.servers.send(servers)
//            case .failure(let error):
//                // TODO: What should be presented when user inputs invalid search text?
//                self?.servers.send([])
//            }
//
//        }
//        .store(in: &disposeBag)

        
    }
    
//    func fetchAllServers() {
//        context.apiService.servers(language: nil, category: nil)
//            .sink { completion in
//                // TODO: Add a reload button when fails to fetch servers initially
//            } receiveValue: { [weak self] result in
//                self?.indexedServers.send(result.value)
//            }
//            .store(in: &disposeBag)
//        
//    }
//    
//    private func searchServersFromAPI(category: Category, searchText: String?, allServers: [Mastodon.Entity.Server]) -> [Mastodon.Entity.Server] {
//        return allServers
//            // 1. Filter the category
//            .filter {
//                switch category {
//                case .all:
//                    return true
//                case .some(let masCategory):
//                    return $0.category.caseInsensitiveCompare(masCategory.category.rawValue) == .orderedSame
//                }
//            }
//            // 2. Filter the searchText
//            .filter {
//                if let searchText = searchText, !searchText.isEmpty {
//                    return $0.domain.lowercased().contains(searchText.lowercased())
//                } else {
//                    return true
//                }
//            }
//    }
}

// MARK: - SignIn methods & structs
extension MastodonPickServerViewModel {
    enum AuthenticationError: Error, LocalizedError {
        case badCredentials
        case registrationClosed
        
        var errorDescription: String? {
            switch self {
            case .badCredentials:               return "Bad Credentials"
            case .registrationClosed:           return "Registration Closed"
            }
        }
        
        var failureReason: String? {
            switch self {
            case .badCredentials:               return "Credentials invalid."
            case .registrationClosed:           return "Server disallow registration."
            }
        }
        
        var helpAnchor: String? {
            switch self {
            case .badCredentials:               return "Please try again."
            case .registrationClosed:           return "Please try another domain."
            }
        }
    }
    
    struct AuthenticateInfo {
        let domain: String
        let clientID: String
        let clientSecret: String
        let authorizeURL: URL
        
        init?(domain: String, application: Mastodon.Entity.Application) {
            self.domain = domain
            guard let clientID = application.clientID,
                let clientSecret = application.clientSecret else { return nil }
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.authorizeURL = {
                let query = Mastodon.API.OAuth.AuthorizeQuery(clientID: clientID)
                let url = Mastodon.API.OAuth.authorizeURL(domain: domain, query: query)
                return url
            }()
        }
    }
    
    func authenticate(info: AuthenticateInfo, pinCodePublisher: PassthroughSubject<String, Never>) {
        pinCodePublisher
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
//                self.isAuthenticating.value = true
                self.mastodonPinBasedAuthenticationViewController?.dismiss(animated: true, completion: nil)
                self.mastodonPinBasedAuthenticationViewController = nil
            })
            .compactMap { [weak self] code -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>? in
                guard let self = self else { return nil }
                return self.context.apiService
                    .userAccessToken(
                        domain: info.domain,
                        clientID: info.clientID,
                        clientSecret: info.clientSecret,
                        code: code
                    )
                    .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
                        let token = response.value
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign in success. Token: %s", ((#file as NSString).lastPathComponent), #line, #function, token.accessToken)
                        return Self.verifyAndSaveAuthentication(
                            context: self.context,
                            info: info,
                            userToken: token
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: swap user access token swap fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                    self.isAuthenticating.value = false
                    self.error.send(error)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let account = response.value
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user %s sign in success", ((#file as NSString).lastPathComponent), #line, #function, account.username)
                
                self.authenticated.send((domain: info.domain, account: account))
            }
            .store(in: &self.disposeBag)
    }
    
    static func verifyAndSaveAuthentication(
        context: AppContext,
        info: AuthenticateInfo,
        userToken: Mastodon.Entity.Token
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: userToken.accessToken)
        let managedObjectContext = context.backgroundManagedObjectContext

        return context.apiService.accountVerifyCredentials(
            domain: info.domain,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
            let account = response.value
            let mastodonUserRequest = MastodonUser.sortedFetchRequest
            mastodonUserRequest.predicate = MastodonUser.predicate(domain: info.domain, id: account.id)
            mastodonUserRequest.fetchLimit = 1
            guard let mastodonUser = try? managedObjectContext.fetch(mastodonUserRequest).first else {
                return Fail(error: AuthenticationError.badCredentials).eraseToAnyPublisher()
            }
            
            let property = MastodonAuthentication.Property(
                domain: info.domain,
                userID: mastodonUser.id,
                username: mastodonUser.username,
                appAccessToken: userToken.accessToken,  // TODO: swap app token
                userAccessToken: userToken.accessToken,
                clientID: info.clientID,
                clientSecret: info.clientSecret
            )
            return managedObjectContext.performChanges {
                _ = APIService.CoreData.createOrMergeMastodonAuthentication(
                    into: managedObjectContext,
                    for: mastodonUser,
                    in: info.domain,
                    property: property,
                    networkDate: response.networkDate
                )
            }
            .tryMap { result in
                switch result {
                case .failure(let error):   throw error
                case .success:              return response
                }
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
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
