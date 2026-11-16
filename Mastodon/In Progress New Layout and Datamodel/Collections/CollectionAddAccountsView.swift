// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import MastodonUI

private let sectionInsets = EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding)

struct CollectionAddAccountsView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(CreateCollectionViewModel.self) private var viewModel
    
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    private var isSearching: Bool { isSearchFieldFocused || !searchText.isEmpty }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                hintHeader
                if isSearching {
                    if viewModel.isSearchInProgress && !searchText.isEmpty {
                        SearchInProgressIndicatorRow()
                    }
                    if viewModel.searchFoundNothing {
                        ScrollView(showsIndicators: false) {
                            emptyState(imageWidth: geo.size.width * 0.5, message: L10nLookup.Timeline.EmptyState.nothingToSeeHere)
                        }
                    } else {
                        searchResults
                    }
                } else if viewModel.accounts.isEmpty {
                    ScrollView(showsIndicators: false) {
                        emptyState(imageWidth: geo.size.width * 0.5, message: L10nLookup.Scene.CreateCollection.AddAccounts.emptyCollectionMessage, secondaryMessage: L10nLookup.Scene.CreateCollection.AddAccounts.accountLimitMessage(limit: viewModel.maxAccountsPerCollection))
                    }
                } else {
                    addedAccounts
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .frame(width: min(maxFeedContentWidth, geo.size.width))
            .frame(width: geo.size.width)
            .padding(.leading, geo.safeAreaInsets.leading)
            .padding(.trailing, geo.safeAreaInsets.trailing)
            .ignoresSafeArea(.container, edges: .horizontal)
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    viewModel.clearSearch()
                }
            }
        }
        .background(isSearching ? Color(UIColor.systemGroupedBackground) : Color(UIColor.systemBackground))
        .createCollectionPageTitle(forStep: .addAccounts, mode: viewModel.mode)
        .toolbar {
            if viewModel.mode == .create, !viewModel.accounts.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigator.push(.collectionEditor(viewModel, step: .details))
                    } label: {
                        Image(phosphor: .arrowRight)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .flipsForRightToLeftLayoutDirection(true)
                    }
                    .buttonStyle(.prominentCircle(diameter: 40))
                    .accessibilityLabel(L10n.Common.Controls.Actions.next)
                }
                .sharedBackgroundVisibilityHidden()
            }
        }
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return // task has been cancelled because the searchText changed
            }
            viewModel.requestSearch(searchText, navigator: navigator)
        }
    }
    
    @ViewBuilder private var hintHeader: some View {
        VStack(alignment: .leading, spacing: standardPadding) {
            Text(L10nLookup.Scene.CreateCollection.AddAccounts.whoWillYouFeature)
            if viewModel.hasPendingAccounts && !isSearching {
                PendingAccountsNote()
            }
            if viewModel.canAddMoreAccounts {
                searchField
            }
            if !viewModel.accounts.isEmpty {
                Text(L10nLookup.Scene.CreateCollection.AddAccounts.accountsAddedCount(viewModel.accounts.count, maxCount: viewModel.maxAccountsPerCollection))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(sectionInsets)
    }
    
    /// We use our own search field so that it can appear in the layout where we want it (below the prompt and above the number of accounts already added) and so that it can easily be hidden when the maximum number of accounts has been reached
    @ViewBuilder private var searchField: some View {
        HStack(spacing: standardPadding) {
            HStack(spacing: tinySpacing) {
                Image(phosphor: .magnifyingGlass)
                    .foregroundStyle(.secondary)
                TextField(L10nLookup.Scene.CreateCollection.AddAccounts.searchBoxPlaceholder, text: $searchText)
                    .focused($isSearchFieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Scene.Search.Searching.clear)
                }
            }
            .padding(.horizontal, doublePadding)
            .padding(.vertical, standardPadding)
            .background(Color(UIColor.tertiarySystemFill), in: .capsule)
            
            if isSearching {
                Button(L10n.Common.Controls.Actions.cancel) {
                    searchText = ""
                    isSearchFieldFocused = false
                }
            }
        }
    }
    
    @ViewBuilder private var searchResults: some View {
        List {
            if !viewModel.availableResults.isEmpty {
                Section {
                    ForEach(viewModel.availableResults, id: \.id) { accountModel in
                        if viewModel.isAlreadyAdded(accountModel) {
                            CreateCollectionAccountRow(account: accountModel.account, dimmedReason: .alreadyAdded, isUpdating: viewModel.isUpdating(accountModel)) {
                                confirmRemove(accountModel)
                            }
                        } else {
                            Button {
                                viewModel.addAccount(accountModel)
                                searchText = ""
                                isSearchFieldFocused = false
                            } label: {
                                CreateCollectionAccountRow(account: accountModel.account)
                            }
                        }
                    }
                }
            }
            if !viewModel.unavailableResults.isEmpty {
                Section {
                    ForEach(viewModel.unavailableResults, id: \.id) { accountModel in
                        CreateCollectionAccountRow(account: accountModel.account, dimmedReason: .ineligible)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: tinySpacing) {
                        Text(L10nLookup.Scene.CreateCollection.AddAccounts.canNotAdd)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(L10nLookup.Scene.CreateCollection.AddAccounts.canNotAddExplainer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    @ViewBuilder private var addedAccounts: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.accounts, id: \.id) { accountModel in
                    CreateCollectionAccountRow(account: accountModel.account, showsStats: true, isUpdating: viewModel.isUpdating(accountModel), isPending: viewModel.isPending(accountModel)) {
                        confirmRemove(accountModel)
                    }
                    .padding(sectionInsets)
                }
            }
        }
    }
    
    private func confirmRemove(_ accountModel: AccountRowViewModel) {
        switch viewModel.mode {
        case .edit:
            navigator.activeAlert = .confirmRemoveAccountFromCollection(username: "@"+accountModel.account.handle, didConfirm: { [viewModel] confirmed in
                guard confirmed else { return }
                viewModel.remove(accountModel)
            })
        case .create:
            // no need to confirm
            withAnimation {
                viewModel.remove(accountModel)
            }
        }
    }
    
    @ViewBuilder private func emptyState(imageWidth: CGFloat, message: String, secondaryMessage: String? = nil) -> some View {
        VStack(spacing: 0) {
            Asset.Asset.emptyStateMastodon.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageWidth)
            Text(message)
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(standardPadding)
            if let secondaryMessage {
                Text(secondaryMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


struct CreateCollectionAccountRow: View {
    let account: MastodonAccount
    var dimmedReason: DimmedReason?
    var showsStats = false
    var isUpdating = false
    var isPending = false
    var onRemove: (() -> Void)? = nil
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    enum DimmedReason {
        case alreadyAdded
        case ineligible
        
        var label: String {
            switch self {
            case .alreadyAdded:
                L10nLookup.Scene.CreateCollection.AddAccounts.alreadyAdded
            case .ineligible:
                L10nLookup.Scene.CreateCollection.AddAccounts.canNotAdd
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: standardPadding) {
            HStack(spacing: spacingBetweenGutterAndContent) {
                HStack(spacing: spacingBetweenGutterAndContent) {
                    AvatarView(style: .circular, size: .large, avatarSource: .url(account.avatarURL))
                        .accessibilityHidden(true)
                    AccountDisplayNameAndHandle(account: account, includeVerifiedLink: false)
                    if isPending {
                        PendingBadge()
                            .fixedSize()
                    }
                }
                .opacity(dimmedReason != nil || isUpdating ? 0.4 : 1)
                .accessibilityElement(children: .combine)
                .accessibilityValue(dimmedReason?.label ?? "")
                .accessibilityActions {
                    if let onRemove, !isUpdating {
                        Button(L10nLookup.Scene.Collections.remove, action: onRemove)
                    }
                }

                if isUpdating {
                    ProgressView()
                } else if let onRemove {
                    RemoveFromCollectionButton(action: onRemove)
                        .accessibilityHidden(voiceOverEnabled)
                }
            }
            if showsStats {
                HStack(spacing: doublePadding) {
                    AccountStatsView(displayType: .largeStackedWithLastActive(account._legacyEntity.lastStatusAt), accountMetrics: account.metrics, onTapOfMetric: nil)
                    if let verifiedLink = account.metadata.verifiedLink {
                        VerifiedLinkLozenge(html: verifiedLink)
                    }
                }
            }
        }
    }
}
    
private struct VerifiedLinkLozenge: View {
    let html: String
    
    var body: some View {
        HStack(spacing: tinySpacing) {
            Asset.Scene.Profile.About.verifiedLinkBadge.swiftUIImage
            MastodonContentView.verifiedLink(html: html)
        }
        .padding(.vertical, tinySpacing)
        .padding(.horizontal, standardPadding)
        .background {
            Capsule()
                .fill(.secondary.opacity(0.2))
        }
    }
}

private struct PendingBadge: View {
    var body: some View {
        Text(L10nLookup.Scene.CreateCollection.AddAccounts.pendingBadge)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
            .padding(.horizontal, standardPadding)
            .background {
                Capsule()
                    .fill(.secondary.opacity(0.2))
            }
    }
}

private struct PendingAccountsNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: standardPadding) {
            Image(systemName: "questionmark")
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(Color(UIColor.tertiarySystemFill), in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: tinySpacing) {
                Text(L10nLookup.Scene.CreateCollection.AddAccounts.pendingAccountsNoteTitle)
                    .fontWeight(.semibold)
                
                Text(L10nLookup.Scene.CreateCollection.AddAccounts.pendingAccountsNoteMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Asset.Colors.FigmaToken.bgSecondary.swiftUIColor, in: .rect(cornerRadius: CornerRadius.large))
        .accessibilityElement(children: .combine)
    }
}
