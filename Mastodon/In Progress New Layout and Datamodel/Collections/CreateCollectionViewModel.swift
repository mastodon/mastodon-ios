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
    @ViewBuilder func createCollectionPageTitle(forStep step: CreateCollectionStep, mode: CreateCollectionViewModel.CollectionEditMode) -> some View {
        switch mode {
        case .create:
            self
                .navigationTitle(L10nLookup.Scene.CreateCollection.title, withSubtitle: L10nLookup.Scene.CreateCollection.stepNumber(step.rawValue, ofTotal: CreateCollectionStep.allCases.count))
                .toolbarTitleDisplayMode(.inline)
        case .edit:
            switch step {
            case .addAccounts:
                self.navigationTitle(L10nLookup.Scene.EditCollection.manageAccountsTitle)
                    .toolbarTitleDisplayMode(.inline)
            case .details:
                self.navigationTitle(L10nLookup.Scene.EditCollection.editDetailsTitle)
                    .toolbarTitleDisplayMode(.inline)
            }
        }
    }
}

@MainActor
@Observable class CreateCollectionViewModel {
    let authBox: MastodonAuthenticationBox
    let mode: CollectionEditMode
    private let didChangeCollection: (() -> Void)?
    private let didReceiveError: ((Error) -> Void)?
    
    enum CollectionEditMode: Equatable {
        case create
        case edit(collectionID: Mastodon.Entity.Collection.ID)
    }
    
    private(set) var accounts: [AccountRowViewModel] = []
    private(set) var availableResults: [AccountRowViewModel] = []
    private(set) var unavailableResults: [AccountRowViewModel] = []
    
    private(set) var isSearchInProgress = false
    private(set) var searchFoundNothing = false
    private var pendingSearchText: String?
    
    private var itemsKnownToServer: [ Mastodon.Entity.Account.ID : Mastodon.Entity.CollectionMember ] = [:]
    
    private var updateQueue = [UpdateRequest]()
    private var currentUpdate: UpdateRequest?
    var isSaving: Bool { currentUpdate != nil }
    
    enum UpdateRequest {
        case create(MastodonNavigationRouter)
        case editDetails(Mastodon.Entity.Collection.ID, MastodonNavigationRouter)
        case addAccount(Mastodon.Entity.Account.ID, toCollection: Mastodon.Entity.Collection.ID)
        case removeAccount(Mastodon.Entity.Account.ID, fromCollection: Mastodon.Entity.Collection.ID)
        
        func affectsAccount(_ accountID: Mastodon.Entity.Account.ID) -> Bool {
            switch self {
            case .addAccount(let id, _), .removeAccount(let id, _):
                return id == accountID
            default: return false
            }
        }
    }

    init(authBox: MastodonAuthenticationBox, didCreateCollection: (() -> Void)? = nil) {
        self.mode = .create
        self.authBox = authBox
        self.didChangeCollection = didCreateCollection
        self.didReceiveError = nil
        self.isSensitive = AuthenticationServiceProvider.shared.activeUserPreferences.postingDefaultSensitive
    }
    
    init(authBox: MastodonAuthenticationBox, editing existing: Mastodon.Entity.CollectionWithAccounts, didChangeCollection: (() -> Void)?, didReceiveError: @escaping ((Error) -> Void)) {
        let collection = existing.collection
        self.authBox = authBox
        self.mode = .edit(collectionID: collection.id)
        self.didChangeCollection = didChangeCollection
        self.didReceiveError = didReceiveError
        
        collectionName = collection.name ?? ""
        collectionDescription = collection.description ?? ""
        collectionTopic = collection.tag?.name ?? ""
        language = collection.language
        isDiscoverable = collection.discoverable ?? true
        isSensitive = collection.sensitive ?? false

        let accountsByID = existing.accounts.reduce(into: [ Mastodon.Entity.Account.ID : Mastodon.Entity.Account ]()) { partialResult, account in
            partialResult[account.id] = account
        }
        
        var rowViewModels: [AccountRowViewModel] = []
        
        var itemsKnownToServer = [ Mastodon.Entity.Account.ID : Mastodon.Entity.CollectionMember ]()
        for item in collection.items {
            guard let accountID = item.account_id, let account = accountsByID[accountID] else { continue }
            itemsKnownToServer[accountID] = item
            rowViewModels.append(AccountRowViewModel(account: MastodonAccount.fromEntity(account, authenticatedDomain: authBox.domain), suggestedBecause: nil))
        }
        accounts = rowViewModels
        self.itemsKnownToServer = itemsKnownToServer
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
        case .collectionEditor(_, step: .addAccounts): return true
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
        switch mode {
        case .create:
            return // all get pushed at once later when the collection is created
        case .edit(let collectionID):
            requestUpdate(.addAccount(account.id, toCollection: collectionID))
        }
    }
    
    func remove(_ account: AccountRowViewModel) {
        switch mode {
        case .create:
            accounts.removeAll { $0.id == account.id }
        case .edit(let collectionID):
            guard !isUpdating(account) else { return }
            requestUpdate(.removeAccount(account.id, fromCollection: collectionID))
        }
    }
    
    func isAlreadyAdded(_ account: AccountRowViewModel) -> Bool {
        accounts.contains { $0.id == account.id }
    }
    
    func isUpdating(_ account: AccountRowViewModel) -> Bool {
        if let currentUpdate, currentUpdate.affectsAccount(account.id) {
            return true
        }
        return updateQueue.contains { $0.affectsAccount(account.id) }
    }
    
    func isPending(_ account: AccountRowViewModel) -> Bool {
        itemsKnownToServer[account.id]?.state == .pending
    }
    
    var hasPendingAccounts: Bool {
        itemsKnownToServer.values.contains { $0.state == .pending }
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
    
    func saveDetails(navigator: MastodonNavigationRouter) {
        guard detailsValid, !isSaving else { return }
        switch mode {
        case .create:
            requestUpdate(.create(navigator))
        case .edit(let collectionID):
            requestUpdate(.editDetails(collectionID, navigator))
        }
    }
    
    private var trimmedName: String { collectionName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedDescription: String { collectionDescription.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedTopic: String { collectionTopic.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "#"))) }
}

private extension CreateCollectionViewModel {
    private func requestUpdate(_ update: UpdateRequest) {
        updateQueue.append(update)
        doNextUpdateIfPossible()
    }
    
    private func doNextUpdateIfPossible() {
        guard !isSaving, !updateQueue.isEmpty else { return }
        let next = updateQueue.removeFirst()
        currentUpdate = next
        Task {
            do {
                try await performUpdate(next)
            } catch {
                didReceiveError?(error)
            }
            currentUpdate = nil
            doNextUpdateIfPossible()
        }
    }
    
    private func performUpdate(_ update: UpdateRequest) async throws {
        switch update {
        case .create(let navigator):
            await doCreateCollection(navigator)
        case .editDetails(let collectionID, let navigator):
            try await doPushNewDetails(collectionID, navigator: navigator)
        case .addAccount(let accountID, let collectionID):
            try await doAddAccount(accountID, toExistingCollection: collectionID)
        case .removeAccount(let accountID, let collectionID):
            try await doRemoveAccount(accountID, fromExistingCollection: collectionID)
        }
    }
    
    private func doCreateCollection(_ navigator: MastodonNavigationRouter) async {
        let query = Mastodon.API.Collections.CreateCollectionQuery(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            language: language,
            tagName: trimmedTopic.isEmpty ? nil : trimmedTopic,
            sensitive: isSensitive,
            discoverable: isDiscoverable,
            accountIDs: accounts.map { $0.account.id }
        )
        do {
            _ = try await APIService.shared.createCollection(query, authenticationBox: authBox)
            didChangeCollection?()
            
            navigator.popCreateCollectionFlow(self)
        } catch {
            navigator.didReceiveError(error)
        }
    }
    
    private func doPushNewDetails(_ collectionID: Mastodon.Entity.Collection.ID, navigator: MastodonNavigationRouter) async throws {
        let query = Mastodon.API.Collections.UpdateCollectionQuery(name: trimmedName, description: trimmedDescription.isEmpty ? nil : trimmedDescription, language: language, tagName: trimmedTopic.isEmpty ? nil : trimmedTopic, sensitive: isSensitive, discoverable: isDiscoverable)
        _ = try await APIService.shared.updateCollection(collectionID: collectionID, query: query, authenticationBox: authBox)
        didChangeCollection?()
        navigator.popCreateCollectionFlow(self)
    }
    
    private func doAddAccount(_ accountID: Mastodon.Entity.Account.ID, toExistingCollection collectionID: Mastodon.Entity.Collection.ID) async throws {
        do {
            let item = try await APIService.shared.addAccountToCollection(collectionID: collectionID, accountID: accountID, authenticationBox: authBox).value
            itemsKnownToServer[accountID] = item
            didChangeCollection?()
        } catch {
            withAnimation {
                accounts.removeAll { $0.id == accountID }
            }
            throw error
        }
    }
    
    private func doRemoveAccount(_ accountID: Mastodon.Entity.Account.ID, fromExistingCollection collectionID: Mastodon.Entity.Collection.ID) async throws {
        guard let itemID = itemsKnownToServer[accountID]?.id else { return }
        try await APIService.shared.deleteCollectionItem(collectionID: collectionID, itemID: itemID, authenticationBox: authBox)
        withAnimation {
            accounts.removeAll { $0.id == accountID }
        }
        itemsKnownToServer.removeValue(forKey: accountID)
        didChangeCollection?()
    }
}

private extension AccountRowViewModel {
    var canBeFeatured: Bool {
        account._legacyEntity.featureApproval?.currentUserCanFeature == true
    }
}
