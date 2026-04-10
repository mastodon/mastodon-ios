// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonCore
import MastodonSDK
import SwiftUI
import MastodonAsset
import MastodonUI

struct ManageListMembershipView: View {
    @Environment(MyListsManagementViewModel.self) var listsViewModel
    @Environment(MastodonNavigationRouter.self) var navigator
    
    var body: some View {
        @Bindable var listsViewModel = listsViewModel
        
        NavigationStack(path: $listsViewModel.navigationPath) {
            VStack {
                Spacer()
                    .frame(height: doublePadding)
                Text("Add \(listsViewModel.accountToAddOrRemove.displayInfo.fullHandle) to lists")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(doublePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if listsViewModel.lists != nil {  // don't try to create a new list when the lists haven't yet loaded
                    newListButton()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, doublePadding)
                }
                    
                Spacer()
                    .frame(height: doublePadding)
                
                ScrollView {
                    if let lists = listsViewModel.lists {
                        VStack {
                            ForEach(lists, id: \.self.id) { list in
                                listRow(list)
                                    .padding(.horizontal, doublePadding)
                                    .padding(.vertical, standardPadding)
                            }
                        }
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
            }
            .navigationDestination(for: ListManagementNavigationDestination.self) { destination in
                switch destination {
                case .createList(let createListViewModel):
                    CreateNewListView()
                        .environment(createListViewModel)
                }
            }
        }
    }
    
    @ViewBuilder func listRow(_ list: Mastodon.Entity.List) -> some View {
        HStack(spacing: 0) {
            MastodonContentView.timelinePost(html: list.title, emojis: listsViewModel.emojis, isInlinePreview: false)
            Spacer()
            AsyncCheckbox(isChecked: listsViewModel.includedInBinding(forList: list.id).animation())
        }
    }
    
    @ViewBuilder func newListButton() -> some View {
        Button {
            listsViewModel.navigationPath.append(.createList(CreateNewListViewModel()))
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Create new list...")
            }
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .padding([.horizontal], 12)
            .padding([.vertical], 14)
            .foregroundStyle(Asset.Colors.accent.swiftUIColor)
            .controlSize(.small)
            .fontWeight(.bold)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.standard)
                    .stroke(Asset.Colors.accent.swiftUIColor)
            }
        }
    }
}

enum ListManagementNavigationDestination: Hashable {
    case createList(CreateNewListViewModel)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .createList:
            hasher.combine("createList")
        }
    }
    
    static func ==(lhs: ListManagementNavigationDestination, rhs: ListManagementNavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.createList, .createList): true
        }
    }
}

@MainActor
@Observable class CreateNewListViewModel {
    var listNameFieldEditingViewModel: MetaTextInputFieldViewModel
    
    var hasValidName: Bool = false
    
    var repliesPolicySelection: RepliesPolicy = .list
    
    var removePostsFromHomeFeed: Bool = false
    
    var isCreatingList: Bool = false
    var createListError: Error?
    
    init() {
        listNameFieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: "", characterLimit: .softLimit(100), autocompleteMastodonItems: false)
        listNameFieldEditingViewModel.contentDidChange = {
            withAnimation {
                self.hasValidName = !self.listNameFieldEditingViewModel.stringContent.isEmpty
            }
        }
    }
    
    enum RepliesPolicy: CaseIterable {
        case none
        case list
        case followed
        
        var title: String {
            switch self {
            case .none:
                "No one"
            case .list:
                "Members of the list"
            case .followed:
                "Any followed user"
            }
        }
        
        var apiPolicy: Mastodon.Entity.ReplyPolicy {
            switch self {
            case .none:
                return .none
            case .list:
                return .list
            case .followed:
                return .followed
            }
        }
    }
    
    func createList() async throws -> Mastodon.Entity.List {
        guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { throw APIService.APIError.explicit(.authenticationMissing) }
        
        let newList = try await Mastodon.API.Lists.createList(
            listName: listNameFieldEditingViewModel.stringContent,
            replyPolicy: repliesPolicySelection.apiPolicy,
            removeFromHome: removePostsFromHomeFeed,
            session: .shared,
            domain: currentUser.domain,
            authorization: currentUser.userAuthorization
        ).singleOutput().value
        
        return newList
    }
}

struct CreateNewListView: View {
    @Environment(MyListsManagementViewModel.self) var presentingViewModel
    @Environment(CreateNewListViewModel.self) var createListViewModel

    var body: some View {
        @Bindable var viewModel = createListViewModel
        
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: tinySpacing) {
                SubsectionHeading(title: "List name", subtitle: nil) // TODO: needs L10n
                MetaTextInputField(allowScroll: false, drawBackground: true, returnKeyType: .done)
                    .environment(viewModel.listNameFieldEditingViewModel)
                    .frame(height: 36)
            }
            
            VStack(alignment: .leading, spacing: tinySpacing) {
                SubsectionHeading(title: "Include replies from list members to", subtitle: nil) // TODO: needs L10n
                Picker(selection: $viewModel.repliesPolicySelection) {
                    ForEach(CreateNewListViewModel.RepliesPolicy.allCases, id: \.self) { replySetting in
                        Text(replySetting.title)
                    }
                } label: {
                    
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            HStack(alignment: .top) {
                SubsectionHeading(title: "Hide members in Home feed", subtitle: "If someone is on this list, hide them in your Home feed to avoid seeing their posts twice.") // TODO: needs L10n
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle("", isOn: $viewModel.removePostsFromHomeFeed)
                    .fixedSize()
            }
            
            if viewModel.hasValidName {
                Spacer()
                    .frame(height: doublePadding)

                Button() {
                    withAnimation {
                        viewModel.isCreatingList = true
                    }
                    
                    Task {
                        do {
                            let newList = try await viewModel.createList()
                            presentingViewModel.didCreateNewList(newList)
                        } catch {
                            viewModel.isCreatingList = false
                            createListViewModel.createListError = error
                        }
                    }
                } label: {
                    ZStack {
                        Text("Create")
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .padding([.horizontal], 12)
                            .padding([.vertical], 14)
                            .foregroundStyle(.white)
                            .controlSize(.small)
                            .fontWeight(.bold)
                            .opacity(createListViewModel.isCreatingList ? 0.0 : 1.0)
                        
                        if createListViewModel.isCreatingList {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: CornerRadius.standard)
                            .fill(Asset.Colors.accent.swiftUIColor)
                            .opacity(createListViewModel.isCreatingList ? 0.3 : 1.0)
                    }
                }
                
                if let error = createListViewModel.createListError {
                    Text("Could not create list: \(error.localizedDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
        }
        .padding(doublePadding)
        .navigationTitle("Create list")
    }
}

@MainActor
@Observable class MyListsManagementViewModel {
    var navigationPath = [ListManagementNavigationDestination]()
    let accountToAddOrRemove: MastodonAccount
    private(set) var lists: [Mastodon.Entity.List]?
    private(set) var listsIncludingThisAccount = Set<Mastodon.Entity.List.ID>()
    private(set) var listsUpdating = Set<Mastodon.Entity.List.ID>()
    private var listMembershipBindings = [Mastodon.Entity.List.ID : Binding<AsyncBool>]()
    let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value
    var emojis: [Mastodon.Entity.Emoji] = []
    
    init(_ accountToAddOrRemove: MastodonAccount) {
        self.accountToAddOrRemove = accountToAddOrRemove
        
        Task { @MainActor in
            guard let currentUser else { return }
            
            emojis = currentUser.cachedAccount?.emojis ?? []
            
            let _listsIncludingThisAccount = (try? await Mastodon.API.Account.getLists(includingAccount: accountToAddOrRemove.id,
                session: .shared,
                domain: currentUser.domain,
                authorization: currentUser.userAuthorization
            ).singleOutput().value) ?? []
            
            let _lists = (try? await Mastodon.API.Lists.getLists(
                session: .shared,
                domain: currentUser.domain,
                authorization: currentUser.userAuthorization
            ).singleOutput().value) ?? []
            
            listsIncludingThisAccount = _listsIncludingThisAccount.reduce(into: Set<Mastodon.Entity.List.ID>()) { partialResult, thisList in  partialResult.insert(thisList.id) }
            lists = _lists
        }
    }
    
    func includedInBinding(forList listID: Mastodon.Entity.List.ID) -> Binding<AsyncBool> {
        if let binding = listMembershipBindings[listID] {
            return binding
        } else {
            let newBinding = Binding<AsyncBool>(
                get: {
                    let isUpdating = self.listsUpdating.contains(listID)
                    switch (self.listsIncludingThisAccount.contains(listID), isUpdating) {
                    case (true, false):
                        return .isTrue
                    case (true, true):
                        return .settingToFalse
                    case (false, false):
                        return .isFalse
                    case (false, true):
                        return .settingToTrue
                    }
                },
                set: { isIncluded in
                    guard let currentUser = self.currentUser else { return }
                    // change our internal bookkeeping and post the change to the api
                    switch isIncluded {
                    case .settingToTrue:
                        if !self.listsIncludingThisAccount.contains(listID) {
                            Task {
                                defer { self.listsUpdating.remove(listID) }
                                self.listsUpdating.insert(listID)
                                do {
                                    let _ = try await APIService.shared.addAccountToList(listID: listID, accountID: self.accountToAddOrRemove.id, authenticationBox: currentUser)
                                    self.listsIncludingThisAccount.insert(listID)
                                } catch {
                                    print("\(error)")
                                }
                            }
                        }
                    case .settingToFalse:
                        if self.listsIncludingThisAccount.contains(listID) {
                            Task {
                                defer { self.listsUpdating.remove(listID) }
                                self.listsUpdating.insert(listID)
                                do {
                                    let _ = try await APIService.shared.removeAccountFromList(listID: listID, accountID: self.accountToAddOrRemove.id, authenticationBox: currentUser)
                                    self.listsIncludingThisAccount.remove(listID)
                                } catch {
                                    print("\(error)")
                                }
                            }
                        }
                    case .isFalse, .isTrue:
                        break
                    case .fetching, .unknown:
                        break
                    }
                }
            )
            listMembershipBindings[listID] = newBinding
            return newBinding
        }
    }
    
    func didCreateNewList(_ newList: Mastodon.Entity.List) {
        guard lists != nil else { return }
        
        let _ = navigationPath.popLast()
        
        let newBinding = includedInBinding(forList: newList.id)
        withAnimation {
            lists!.insert(newList, at: 0)
            newBinding.wrappedValue = .settingToTrue
        }
    }
}

struct AsyncCheckbox: View {
    @Binding var isChecked: AsyncBool
    
    var body: some View {
        currentView
            .onTapGesture {
                switch isChecked {
                case .isFalse:
                    isChecked = .settingToTrue
                case .isTrue:
                    isChecked = .settingToFalse
                default:
                    break
                }
            }
    }
    
    @ViewBuilder var currentView: some View {
        ZStack {
            switch isChecked {
            case .unknown:
                EmptyView()
            case .fetching:
                EmptyView()
            case .isTrue, .settingToFalse:
                Image(systemName: "checkmark.square.fill")
            case .isFalse, .settingToTrue:
                Image(systemName: "square")
            }
        }
        .foregroundStyle(isChecked.isTrue ? Asset.Colors.accent.swiftUIColor : .primary)
        .opacity(isChecked.isUpdating ? 0.3 : 1)
    }
    
    // TODO: Accessibility
}

extension AsyncBool {
    var isUpdating: Bool {
        switch self {
        case .settingToTrue, .settingToFalse, .fetching:
            return true
        case .unknown, .isTrue, .isFalse:
            return false
        }
    }
    
    var isTrue: Bool {
        switch self {
        case .isTrue:
            return true
        default:
            return false
        }
    }
}
