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
    let unindexedServers = CurrentValueSubject<[Mastodon.Entity.Server], Never>([])
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
        Publishers.CombineLatest(
            filteredIndexedServers.eraseToAnyPublisher(),
            unindexedServers.eraseToAnyPublisher()
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
                attribute.isLast = false
                let item = PickServerItem.server(server: server, attribute: attribute)
                guard !serverItems.contains(item) else { continue }
                serverItems.append(item)
            }
            for server in unindexedServers {
                let attribute = oldSnapshotServerItemAttributeDict[server.domain] ?? PickServerItem.ServerItemAttribute(isLast: false, isExpand: false)
                attribute.isLast = false
                let item = PickServerItem.server(server: server, attribute: attribute)
                guard !serverItems.contains(item) else { continue }
                serverItems.append(item)
            }
            if case let .server(_, attribute) = serverItems.last {
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
                case .failure:
                    // TODO: What should be presented when user inputs invalid search text?
                    self.unindexedServers.send([])
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
