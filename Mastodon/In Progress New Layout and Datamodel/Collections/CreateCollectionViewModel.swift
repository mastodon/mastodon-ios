// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonLocalization
import MastodonSDK
import MastodonUI

enum CreateCollectionStep: Int, CaseIterable {
    case addAccounts = 1
    case details
}

extension View {
    func createCollectionPageTitle(forStep step: CreateCollectionStep) -> some View {
        self
            .navigationTitle(L10nLookup.Scene.CreateCollection.title, withSubtitle: L10nLookup.Scene.CreateCollection.stepNumber(step.rawValue, ofTotal: CreateCollectionStep.allCases.count))
            .toolbarTitleDisplayMode(.inline)
    }
}

@MainActor
@Observable class CreateCollectionViewModel {
    let authBox: MastodonAuthenticationBox
    private let didCreateCollection: (() -> Void)?
    
    private(set) var accounts: [AccountRowViewModel] = []
    private(set) var availableResults: [AccountRowViewModel] = []
    private(set) var unavailableResults: [AccountRowViewModel] = []
    
    private(set) var isSearchInProgress = false
    private(set) var searchFoundNothing = false
    private var pendingSearchText: String?
    
    
    init(authBox: MastodonAuthenticationBox, didCreateCollection: (() -> Void)? = nil) {
        self.authBox = authBox
        self.didCreateCollection = didCreateCollection
        self.isSensitive = AuthenticationServiceProvider.shared.activeUserPreferences.postingDefaultSensitive
    }
    
    var maxAccountsPerCollection: Int { authBox.authentication.maxAccountsPerCollection }
    var maxCollectionNameLength: Int { authBox.authentication.maxCollectionNameLength }
    var maxCollectionDescriptionLength: Int { authBox.authentication.maxCollectionDescriptionLength }
    var canAddMoreAccounts: Bool { accounts.count <  maxAccountsPerCollection}
    
    var collectionName = ""
    var collectionDescription = ""
    var collectionTopic = ""
    var language: String?
    var isDiscoverable = true
    var isSensitive: Bool
    private(set) var isCreating = false
    
    // MARK - Add Accounts
    
    func requestSearch(_ searchText: String, navigator: MastodonNavigationRouter) {
        pendingSearchText = searchText
        guard !isSearchInProgress else { return }
        isSearchInProgress = true
        Task {
            while let nextSearchText = pendingSearchText {
                pendingSearchText = nil
                do {
                    try await search(nextSearchText)
                } catch {
                    if pendingSearchText == nil && isAddAccountsStepOnScreen(navigator) {
                        // this is the most up to date search and we are still on the search screen
                        navigator.didReceiveError(error)
                    }
                }
            }
            isSearchInProgress = false
        }
    }
    
    private func isAddAccountsStepOnScreen(_ navigator: MastodonNavigationRouter) -> Bool {
        guard let onScreen = navigator.navigationPath.last else { return false }
        switch onScreen {
        case .createNewCollection(_, step: .addAccounts): return true
        default: return false
        }
    }
    
    private func search(_ searchText: String) async throws {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSearchText.count > 2 else { clearResults(); return }
        let query = Mastodon.API.V2.Search.Query(q: trimmedSearchText, type: SearchScope.people.searchType, resolve: true)
        let results = try await APIService.shared.search(query: query, authenticationBox: authBox).value.accounts
        try Task.checkCancellation()
        let candidates = results
            .map { AccountRowViewModel(account: MastodonAccount.fromEntity($0, authenticatedDomain: authBox.domain), suggestedBecause: nil) }
        availableResults = candidates.filter { $0.canBeFeatured }
        unavailableResults = candidates.filter { !$0.canBeFeatured }
        searchFoundNothing = candidates.isEmpty
    }
    
    func addAccount(_ account: AccountRowViewModel) {
        guard canAddMoreAccounts, !isAlreadyAdded(account) else { return }
        accounts.append(account)
    }
    
    func remove(_ account: AccountRowViewModel) {
        accounts.removeAll { $0.id == account.id }
    }
    
    func isAlreadyAdded(_ account: AccountRowViewModel) -> Bool {
        accounts.contains { $0.id == account.id }
    }
    
    func clearSearch() {
        clearResults()
        if isSearchInProgress {
            pendingSearchText = ""
        }
    }
    
    private func clearResults() {
        availableResults = []
        unavailableResults = []
        searchFoundNothing = false
    }
    
    // MARK - Details
    var nameIsTooLong: Bool {
        trimmedName.count > maxCollectionNameLength
    }
    
    var nameIsValid: Bool {
        !trimmedName.isEmpty && !nameIsTooLong
    }
    
    var descriptionIsValid: Bool {
        trimmedDescription.count <= maxCollectionDescriptionLength
    }
    
    var detailsValid: Bool {
        nameIsValid && descriptionIsValid
    }
    
    var languageName: String? {
        guard let language else { return nil }
        guard let label = Language(id: language)?.label else { return language }
        return String(label.characters)
    }
    
    func createCollection(navigator: MastodonNavigationRouter) {
        guard detailsValid, !isCreating else { return }
        isCreating = true
        let query = Mastodon.API.Collections.CreateCollectionQuery(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            language: language,
            tagName: trimmedTopic.isEmpty ? nil : trimmedTopic,
            sensitive: isSensitive,
            discoverable: isDiscoverable,
            accountIDs: accounts.map { $0.account.id }
        )
        Task {
            defer { isCreating = false }
            do {
                _ = try await APIService.shared.createCollection(query, authenticationBox: authBox)
                didCreateCollection?()
                
                navigator.popCreateCollectionFlow(self)
            } catch {
                navigator.didReceiveError(error)
            }
        }
    }
    
    private var trimmedName: String { collectionName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedDescription: String { collectionDescription.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedTopic: String { collectionTopic.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "#"))) }
}

private extension AccountRowViewModel {
    var canBeFeatured: Bool {
        account._legacyEntity.featureApproval?.currentUserCanFeature == true
    }
}
