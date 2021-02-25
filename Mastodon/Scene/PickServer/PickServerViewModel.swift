//
//  PickServerViewModel.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import OSLog
import Combine
import MastodonSDK
import CoreDataStack

class PickServerViewModel: NSObject {
    enum PickServerMode {
        case SignUp
        case SignIn
    }
    
    enum Section: CaseIterable {
        case title
        case categories
        case search
        case serverList
    }
    
    enum Category {
        // `All` means search for all categories
        case All
        // `Some` means search for specific category
        case Some(Mastodon.Entity.Category)
        
        var title: String {
            switch self {
            case .All:
                return L10n.Scene.ServerPicker.Button.Category.all
            case .Some(let masCategory):
                // TODO: Use emoji as placeholders
                switch masCategory.category {
                case .academia:
                    return "📚"
                case .activism:
                    return "✊"
                case .food:
                    return "🍕"
                case .furry:
                    return "🦁"
                case .games:
                    return "🕹"
                case .general:
                    return "GE"
                case .journalism:
                    return "📰"
                case .lgbt:
                    return "🏳️‍🌈"
                case .regional:
                    return "📍"
                case .art:
                    return "🎨"
                case .music:
                    return "🎼"
                case .tech:
                    return "📱"
                case ._other:
                    return "❓"
                }
            }
        }
    }
    
    let mode: PickServerMode
    let context: AppContext
    
    var categories = [Category]()
    let selectCategoryIndex = CurrentValueSubject<Int, Never>(0)
    
    let searchText = CurrentValueSubject<String?, Never>(nil)
    
    let allServers = CurrentValueSubject<[Mastodon.Entity.Server], Never>([])
    let searchedServers = CurrentValueSubject<[Mastodon.Entity.Server], Error>([])
    
    let selectedServer = CurrentValueSubject<Mastodon.Entity.Server?, Never>(nil)
    let error = PassthroughSubject<Error, Never>()
    let authenticated = PassthroughSubject<(domain: String, account: Mastodon.Entity.Account), Never>()
    
    private var disposeBag = Set<AnyCancellable>()
    
    weak var tableView: UITableView?
    
    private var expandServerDomainSet = Set<String>()
    
    var mastodonPinBasedAuthenticationViewController: UIViewController?
    
    init(context: AppContext, mode: PickServerMode) {
        self.context = context
        self.mode = mode
        super.init()
        
        configure()
    }
    
    private func configure() {
        let masCategories = context.apiService.stubCategories()
        categories.append(.All)
        categories.append(contentsOf: masCategories.map { Category.Some($0) })
        
        Publishers.CombineLatest3(
            selectCategoryIndex,
            searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).removeDuplicates(),
            allServers
        )
        .flatMap { [weak self] (selectCategoryIndex, searchText, allServers) -> AnyPublisher<Result<[Mastodon.Entity.Server], Error>, Never> in
            guard let self = self else { return Just(Result.success([])).eraseToAnyPublisher() }
            
            // 1. Search from the servers recorded in joinmastodon.org
            let searchedServersFromAPI = self.searchServersFromAPI(category: self.categories[selectCategoryIndex], searchText: searchText, allServers: allServers)
            if !searchedServersFromAPI.isEmpty {
                // If found servers, just return
                return Just(Result.success(searchedServersFromAPI)).eraseToAnyPublisher()
            }
            // 2. No server found in the recorded list, check if searchText is a valid mastodon server domain
            if let toSearchText = searchText, !toSearchText.isEmpty {
                return self.context.apiService.instance(domain: toSearchText)
                    .map { return Result.success([Mastodon.Entity.Server(instance: $0.value)]) }
                    .catch({ error -> Just<Result<[Mastodon.Entity.Server], Error>> in
                        return Just(Result.failure(error))
                    })
                    .eraseToAnyPublisher()
            }
            return Just(Result.success(searchedServersFromAPI)).eraseToAnyPublisher()
        }
        .sink { _ in
            
        } receiveValue: { [weak self] result in
            switch result {
            case .success(let servers):
                self?.searchedServers.send(servers)
            case .failure(let error):
                // TODO: What should be presented when user inputs invalid search text?
                self?.searchedServers.send([])
            }
            
        }
        .store(in: &disposeBag)

        
    }
    
    func fetchAllServers() {
        context.apiService.servers(language: nil, category: nil)
            .sink { error in
                print("11")
            } receiveValue: { [weak self] result in
                self?.allServers.send(result.value)
            }
            .store(in: &disposeBag)
        
    }
    
    private func searchServersFromAPI(category: Category, searchText: String?, allServers: [Mastodon.Entity.Server]) -> [Mastodon.Entity.Server] {
        return allServers
            // 1. Filter the category
            .filter {
                switch category {
                case .All:
                    return true
                case .Some(let masCategory):
                    return $0.category.caseInsensitiveCompare(masCategory.category.rawValue) == .orderedSame
                }
            }
            // 2. Filter the searchText
            .filter {
                if let searchText = searchText, !searchText.isEmpty {
                    return $0.domain.lowercased().contains(searchText.lowercased())
                } else {
                    return true
                }
            }
    }
}

extension PickServerViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let category = Section.allCases[section]
        switch category {
        case .title:
            return 20
        case .categories:
            // Since category view has a blur shadow effect, its height need to be large than the actual height,
            // Thus we reduce the section header's height by 10, and make the category cell height 60+20(10 inset for top and bottom)
            return 10
        case .search:
            // Same reason as above
            return 10
        case .serverList:
            // Header with 1 height as the separator
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: false)
            selectedServer.send(nil)
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        selectedServer.send(searchedServers.value[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selectedServer.send(nil)
    }
}

extension PickServerViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Self.Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Self.Section.allCases[section]
        switch section {
        case .title,
             .categories,
             .search:
            return 1
        case .serverList:
            return searchedServers.value.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = Self.Section.allCases[indexPath.section]
        switch section {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerTitleCell.self), for: indexPath) as! PickServerTitleCell
            return cell
        case .categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCategoriesCell.self), for: indexPath) as! PickServerCategoriesCell
            cell.dataSource = self
            cell.delegate = self
            return cell
        case .search:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerSearchCell.self), for: indexPath) as! PickServerSearchCell
            cell.delegate = self
            return cell
        case .serverList:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCell.self), for: indexPath) as! PickServerCell
            let server = searchedServers.value[indexPath.row]
            cell.server = server
            if expandServerDomainSet.contains(server.domain) {
                cell.mode = .expand
            } else {
                cell.mode = .collapse
            }
            if server == selectedServer.value {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
            
            cell.delegate = self
            return cell
        }
    }
}

extension PickServerViewModel: PickServerCategoriesDataSource, PickServerCategoriesDelegate {
    func numberOfCategories() -> Int {
        return categories.count
    }
    
    func category(at index: Int) -> Category {
        return categories[index]
    }
    
    func selectedIndex() -> Int {
        return selectCategoryIndex.value
    }
    
    func pickServerCategoriesCell(didSelect index: Int) {
        selectCategoryIndex.send(index)
    }
}

extension PickServerViewModel: PickServerSearchCellDelegate {
    func pickServerSearchCell(didChange searchText: String?) {
        self.searchText.send(searchText)
    }
}

extension PickServerViewModel: PickServerCellDelegate {
    func pickServerCell(modeChange server: Mastodon.Entity.Server, newMode: PickServerCell.Mode, updates: (() -> Void)) {
        if newMode == .collapse {
            expandServerDomainSet.remove(server.domain)
        } else {
            expandServerDomainSet.insert(server.domain)
        }
        
        tableView?.performBatchUpdates(updates, completion: nil)
    }
}

// MARK: - SignIn methods & structs
extension PickServerViewModel {
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
extension PickServerViewModel {
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
