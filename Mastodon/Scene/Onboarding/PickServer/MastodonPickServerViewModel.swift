//
//  MastodonPickServerViewModel.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import Combine
import GameplayKit
import MastodonSDK
import CoreDataStack
import OrderedCollections
import MastodonCore
import MastodonUI
import MastodonLocalization

@MainActor
class MastodonPickServerViewModel: NSObject {

    enum EmptyStateViewState {
        case none
        case loading
        case badNetwork
    }
    
    var disposeBag = Set<AnyCancellable>()
    
    let serverSectionHeaderView = PickServerServerSectionTableHeaderView()

    // input
    let categoryPickerItems: [CategoryPickerItem] = {
        var items: [CategoryPickerItem] = []
        items.append(.language(language: nil))
        items.append(.signupSpeed(manuallyReviewed: nil))
        items.append(contentsOf: APIService.stubCategories().map { CategoryPickerItem.category(category: $0) })
        return items
    }()
    let selectCategoryItem = CurrentValueSubject<CategoryPickerItem?, Never>(nil)
    let searchText = CurrentValueSubject<String, Never>("")
    let selectedLanguage = CurrentValueSubject<String?, Never>(nil)
    let manualApprovalRequired = CurrentValueSubject<Bool?, Never>(nil)
    let allLanguages = CurrentValueSubject<[Mastodon.Entity.Language], Never>([])
    let indexedServers = CurrentValueSubject<[Mastodon.Entity.Server], Never>([])
    let unindexedServers = CurrentValueSubject<[Mastodon.Entity.Server]?, Never>([])    // set nil when loading
    let viewWillAppear = PassthroughSubject<Void, Never>()
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    let scrollToTop = PassthroughSubject<Void, Never>()
    @Published var additionalTableViewInsets: UIEdgeInsets = .zero
    
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
    let loadingIndexedServersError = CurrentValueSubject<Error?, Never>(nil)
    let emptyStateViewState = CurrentValueSubject<EmptyStateViewState, Never>(.none)
    
    let joinServer: (Mastodon.Entity.Server) async throws ->()
    let displayError: (Error)->()
        
    init(joinServer: @escaping (Mastodon.Entity.Server) async throws ->(), displayError: @escaping (Error)->()) {
        self.joinServer = joinServer
        self.displayError = displayError
        super.init()
        configure()
    }
    
    
}

extension MastodonPickServerViewModel {
    
    private func configure() {

        APIService.shared.languages().sink { completion in
            
        } receiveValue: { response in
            var availableLanguages = response.value.reduce(into: [ String : Mastodon.Entity.Language ]()) { partialResult, language in
                partialResult[language.locale] = language
            }
            let userPreferredLanguages = Locale.preferredLanguages.compactMap { appleLanguageIdentifier in
                let localeIdentifier: String
                if let firstPortion = appleLanguageIdentifier.split(separator: "-", maxSplits: 1).first {
                    localeIdentifier = String(firstPortion)
                } else {
                    localeIdentifier = appleLanguageIdentifier
                }
                return availableLanguages.removeValue(forKey: localeIdentifier)
            }
            let otherLanguages = response.value.compactMap { language in
                return availableLanguages[language.locale]
            }
            let sortedOthers = otherLanguages.sorted { first, second in
                switch (first.language, second.language) {
                case (nil, nil):
                    return false
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                default:
                    return false
                }
            }
            
            self.allLanguages.value = userPreferredLanguages + sortedOthers
        }
        .store(in: &disposeBag)

        Publishers.CombineLatest(
            isLoadingIndexedServers,
            loadingIndexedServersError
        )
        .map { isLoadingIndexedServers, loadingIndexedServersError -> EmptyStateViewState in
            if isLoadingIndexedServers {
                if loadingIndexedServersError != nil {
                    return .badNetwork
                } else {
                    return .loading
                }
            } else {
                return .none
            }
        }
        .assign(to: \.value, on: emptyStateViewState)
        .store(in: &disposeBag)


        Publishers.CombineLatest4(
            indexedServers.eraseToAnyPublisher(),
            selectCategoryItem.eraseToAnyPublisher(),
            searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).removeDuplicates(),
            Publishers.CombineLatest(
                selectedLanguage.eraseToAnyPublisher(),
                manualApprovalRequired.eraseToAnyPublisher()
            ).map { selectedLanguage, manualApprovalRequired -> (selectedLanguage: String?, manualApprovalRequired: Bool?) in
                (selectedLanguage, manualApprovalRequired)
            }
        )
        .map { [weak self] indexedServers, selectCategoryItem, searchText, filters -> [Mastodon.Entity.Server] in
            var indexedServers = indexedServers

            var _indexedServers: [Mastodon.Entity.Server] = []

            let sortedInstantSignupServers = indexedServers
                .filter { $0.approvalRequired == false }
                .sorted { $0.lastWeekUsers >= $1.lastWeekUsers }
            let sortedApprovalRequiredServers = indexedServers
                .filter { $0.approvalRequired }
                .sorted { $0.lastWeekUsers >= $1.lastWeekUsers }

            _indexedServers.append(contentsOf: sortedInstantSignupServers)
            _indexedServers.append(contentsOf: sortedApprovalRequiredServers)

            if _indexedServers.count == indexedServers.count {
                indexedServers = _indexedServers
            } else {
                assertionFailure("should not change dataset size")
            }
            
            // Filter the indexed servers by category or search text
            switch selectCategoryItem {
            case .language(_), .signupSpeed(_):
                return MastodonPickServerViewModel.filterServers(servers: indexedServers, language: filters.selectedLanguage, manualApprovalRequired: filters.manualApprovalRequired, category: nil, searchText: searchText)
            case .category(let category):
                self?.scrollToTop.send()
                return MastodonPickServerViewModel.filterServers(servers: indexedServers, language: filters.selectedLanguage, manualApprovalRequired: filters.manualApprovalRequired, category: category.category.rawValue, searchText: searchText)
            case nil:
                self?.scrollToTop.send()
                return MastodonPickServerViewModel.filterServers(servers: indexedServers, language: filters.selectedLanguage, manualApprovalRequired: filters.manualApprovalRequired, category: nil, searchText: searchText)
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
                return APIService.shared.webFinger(domain: domain)
                    .flatMap { domain -> AnyPublisher<Result<Mastodon.Response.Content<[Mastodon.Entity.Server]>, Error>, Never> in
                        return APIService.shared.instance(domain: domain, authenticationBox: nil)
                            .map { response -> Result<Mastodon.Response.Content<[Mastodon.Entity.Server]>, Error>in
                                let newResponse = response.map { [Mastodon.Entity.Server(domain: domain, instance: $0)] }
                                return Result.success(newResponse)
                            }
                            .catch { error in
                                return Just(Result.failure(error))
                            }
                            .eraseToAnyPublisher()
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

    func chooseRandomServer() -> Mastodon.Entity.Server? {

        let language = Locale.autoupdatingCurrent.language.languageCode?.identifier.lowercased() ?? "en"

        let servers = indexedServers.value
        guard servers.isNotEmpty else { return nil }

        let generalServers = servers.filter {
            $0.categories.contains("general")
        }
        
        let randomServer: Mastodon.Entity.Server?
        
        let noApprovalRequired = generalServers.filter { !$0.approvalRequired }
        let approvalRequired = generalServers.filter { $0.approvalRequired }
        
        let languageMatchesWithoutApproval = noApprovalRequired.filter { $0.language.lowercased() == language }
        let languageMatchesWithApproval = approvalRequired.filter { $0.language.lowercased() == language }
        let languageDoesNotMatchWithoutApproval = noApprovalRequired.filter { $0.language.lowercased() != language }
        let languageDoesNotMatchWithApproval = approvalRequired.filter { $0.language.lowercased() != language }

        switch (
            languageMatchesWithoutApproval.isEmpty,
            languageMatchesWithApproval.isEmpty,
            languageDoesNotMatchWithoutApproval.isEmpty,
            languageDoesNotMatchWithApproval.isEmpty
        ) {
        case (true, true, true, true):
            randomServer = generalServers.randomElement()
        case (true, true, true, false):
            randomServer = languageDoesNotMatchWithApproval.randomElement()
        case (true, true, false, _):
            randomServer = languageDoesNotMatchWithoutApproval.randomElement()
        case (true, false, _, _):
            randomServer = languageMatchesWithApproval.randomElement()
        case (false, _, _, _):
            randomServer = languageMatchesWithoutApproval.randomElement()
        }

        return randomServer ?? servers.randomElement() ?? servers.first
    }
}

extension MastodonPickServerViewModel {
    private static func filterServers(servers: [Mastodon.Entity.Server], language: String? = nil, manualApprovalRequired: Bool? = nil, category: String?, searchText: String) -> [Mastodon.Entity.Server] {
        let filteredServers = servers
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
            .filter {
                guard let language else { return true }

                return $0.language.lowercased() == language.lowercased()
            }
            .filter {
                guard let manualApprovalRequired else { return true }

                print("\($0.domain) \($0.approvalRequired) < \(manualApprovalRequired)")
                return $0.approvalRequired == manualApprovalRequired
            }
        return filteredServers
    }
}
