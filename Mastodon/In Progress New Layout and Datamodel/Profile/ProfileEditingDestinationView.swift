// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonSDK
import MastodonCore
import MastodonUI
import MastodonLocalization

class ProfileEditingDestinationHostingViewController: UIHostingController<AnyView> {
    private let viewModel: ProfileViewModel
    
    init(_ type: ProfileEditDestinationType, navigator: MastodonNavigationRouter) {
        let viewModel = type.profileViewModel
        self.viewModel = viewModel
        super.init(rootView: AnyView(ProfileEditingDestinationView(destinationType: type).environment(viewModel).environment(viewModel.editingViewModel).environment(navigator)))
        
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDestinationType {
    var doNotPad: Bool {
        switch self {
        case .reorderCustomFields, .featuredHashtags, .addHashtag, .displayName, .bio, .customFields, .editCustomField, .profileTabSettings:
            true
        case .verifiedLinkInstructions:
            false
        }
    }
}

struct ProfileEditingDestinationView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let destinationType: ProfileEditDestinationType
    
    var body: some View {
        if destinationType.expectsModalPresentation {
            NavigationStack() {
                contents
                    .padding(destinationType.doNotPad ? 0 : doublePadding)
                    .navigationTitle(profileViewModel.navigationTitle(destinationType))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        if destinationType.expectsModalPresentation {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    profileViewModel.discardEdits(destinationType)
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                switch editingViewModel.editingStatus?.saveButton {
                                case .noButton, .none:
                                    EmptyView()
                                case .canSave:
                                    Button {
                                        Task {
                                            do {
                                                try await profileViewModel.commitEdits()
                                                dismiss()
                                            } catch {
                                                navigator.didReceiveError(error)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "checkmark")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Asset.Colors.accent.swiftUIColor)
                                case .saveInProgress:
                                    ProgressView().progressViewStyle(.circular)
                                }
                            }
                        }
                    }
            }
        } else {
            contents
                .padding(destinationType.doNotPad ? 0 : doublePadding)
                .navigationTitle(profileViewModel.navigationTitle(destinationType))
                .navigationBarTitleDisplayMode(.inline)
        }
      
    }
    
    @ViewBuilder var contents: some View {
        switch destinationType {
        case .displayName:
            EditSingleTextView(allowTextScroll: false, textViewHeight: 36, returnKeyType: .done)
                .environment(editingViewModel)
                .environment(editingViewModel.displayNameFieldEditingViewModel)
        case .bio:
            EditSingleTextView(allowTextScroll: true, textViewHeight: 150, returnKeyType: .done)
                .environment(editingViewModel)
                .environment(editingViewModel.bioFieldEditingViewModel)
        case .customFields:
            CustomProfileFieldsEditor()
                .environment(navigator)
                .environment(profileViewModel)
                .environment(editingViewModel)
        case .featuredHashtags:
            FeaturedHashtagsEditor()
                .environment(navigator)
                .environment(editingViewModel)
                .environment(profileViewModel.featuredHashtagsModel)
        case .profileTabSettings:
            ProfileTabSettingsEditor()
                .environment(editingViewModel)
        case .verifiedLinkInstructions(let profileViewModel):
            let accountUrl = profileViewModel.account?.metadata.profileUrl?.absoluteString
            VerifiedLinkInstructions(accountUrl: accountUrl)
        case .editCustomField(let profileViewModel):
            EditFieldView()
                .environment(profileViewModel.editingViewModel)
        case .reorderCustomFields(let profileViewModel):
            ReorderCustomFieldsView()
                .environment(profileViewModel)
                .environment(profileViewModel.editingViewModel)
        case .addHashtag(let profileViewModel):
            AddFeaturedHashtagView()
                .environment(navigator)
                .environment(profileViewModel.featuredHashtagsModel)
                .environment(profileViewModel.featuredHashtagsModel.autoCompleteSuggestionsViewModel)
        }
    }
}

extension ProfileViewModel {
    func navigationTitle(_ destination: ProfileEditDestinationType) -> String {
        switch destination {
        case .displayName:
            return L10nLookup.Scene.EditProfile.SubpageTitle.editDisplayName
        case .bio:
            if bioIsEmpty {
                return L10nLookup.Scene.EditProfile.SubpageTitle.addBio
            } else {
                return L10nLookup.Scene.EditProfile.SubpageTitle.editBio
            }
        case .customFields:
            return L10nLookup.Scene.EditProfile.SubpageTitle.customFields
        case .featuredHashtags:
            return L10nLookup.Scene.EditProfile.SubpageTitle.featuredHashtags
        case .profileTabSettings:
            return L10nLookup.Scene.EditProfile.SubpageTitle.profileTabSettings
        case .verifiedLinkInstructions:
            return L10nLookup.Scene.EditProfile.SubpageTitle.verifiedLinkHelp
        case .editCustomField(let profileViewModel):
            guard let fieldEditingState = profileViewModel.editingViewModel.fieldEditingState else { return "" }
            switch fieldEditingState.editingField {
            case .create:
                return L10nLookup.Scene.EditProfile.SubpageTitle.addField
            case .edit:
                return L10nLookup.Scene.EditProfile.SubpageTitle.editField
            }
        case .reorderCustomFields:
            return L10nLookup.Scene.EditProfile.SubpageTitle.reorderFields
        case .addHashtag:
            return L10nLookup.Scene.EditProfile.SubpageTitle.addHashtag
        }
    }
}

struct EditSingleTextView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    @Environment(MetaTextInputFieldViewModel.self) var textInputModel
    
    @FocusState var isFocused: Bool
    
    let allowTextScroll: Bool
    let textViewHeight: CGFloat
    let returnKeyType: UIReturnKeyType
    
    var body: some View {
        List {
            Section {
                MetaTextInputField(allowScroll: allowTextScroll, drawBackground: false, returnKeyType: returnKeyType)
                    .frame(height: textViewHeight)
                    .focused($isFocused)
            } footer : {
                CharacterLimitTip(showCounterOnly: false)
            }
        }
        .onAppear() {
            isFocused = true
        }
        .onChange(of: textInputModel.stringContent) { oldValue, newValue in
            if newValue.last == "\n" {
                isFocused = false
                profileViewModel.checkForEditingChanges()
            }
        }
    }
}

struct CharacterLimitTip: View {
    @Environment(MetaTextInputFieldViewModel.self) var inputModel
    @State var textHasChanged = false
    
    let showCounterOnly: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            let tipText = charCountTipText
            if !showCounterOnly, let tipText {
                Text(tipText)
                    .foregroundStyle(Color.secondary)
            }
            if tipText == nil || textHasChanged {
                Text(charCountDisplay(forCharacterCount: inputModel.characterCount))
                    .foregroundStyle(limitMessageColor)
                    .monospaced()
            }
        }
        .font(.footnote)
        .onChange(of: inputModel.stringContent) { oldValue, newValue in
            guard !textHasChanged else { return }
            textHasChanged = true
        }
    }
    
    var charCountTipText: String? {
        // TODO: L10n
        switch (inputModel.characterLimit.softLimit, inputModel.characterLimit.hardLimit) {
        case (nil, nil): // no limits
           return nil
        case (let softLimit, nil):  // only a soft limit
            return "Tip: try to keep this short, under \(softLimit!) characters is best"
        case (nil, _):  // only a hard limit
            return nil
        case (let softLimit, let hardLimit):
            guard hardLimit! > softLimit! else { /*effectively, there is only a hard limit*/ return nil }
            return "Tip: try to keep this short, under \(softLimit!) characters is best"
        }
    }
    
    func charCountDisplay(forCharacterCount usedCharacterCount: Int) -> String {
        // TODO: L10n
        if let characterLimit {
            return "\(usedCharacterCount)/\(characterLimit) characters"
        } else {
            return "\(usedCharacterCount) characters"
        }
    }
    
    var characterLimit: Int? {
        return inputModel.characterLimit.hardLimit ?? inputModel.characterLimit.softLimit
    }
    
    var limitMessageColor: Color {
        if let hardLimit = inputModel.characterLimit.hardLimit, inputModel.characterCount > hardLimit {
            return .red
        } else if let softLimit = inputModel.characterLimit.softLimit, inputModel.characterCount > softLimit {
            return .yellow
        } else {
            return .secondary
        }
    }
}

extension ProfileViewModel {
    func discardEdits(_ editType: ProfileEditDestinationType) {
        switch editType {
        case .displayName(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.displayNameFieldEditingViewModel.discardChanges()
        case .bio(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.bioFieldEditingViewModel.discardChanges()
        case .customFields(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.discardCustomFieldEdits()
        case .featuredHashtags(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.discardFeaturedHashtagEdits()
        case .profileTabSettings(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            assertionFailure("profile tab setting changes are saved immediately and cannot be discarded")
            break
        case .verifiedLinkInstructions(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            break
        case .editCustomField(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.discardCurrentCustomFieldEdit()
        case .reorderCustomFields(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.discardCustomFieldEdits()
        case .addHashtag(let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            break
        }
    }
}

extension ProfileEditingViewModel {
    func discardCurrentCustomFieldEdit() {
        if fieldEditingState != nil {
            fieldEditingState = nil
        }
    }
    
    func discardCustomFieldEdits() {
        if customFields != initialInfo?.metadata.customFieldsForEdit {
            customFields = initialInfo?.metadata.customFieldsForEdit
        }
    }
    
    func discardFeaturedHashtagEdits() {
        if originalFeaturedTags != editedFeaturedTags {
            editedFeaturedTags = originalFeaturedTags
        }
    }
}

struct ProfileTabSettingsEditor: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    @State var showMediaTabToggleState = false
    @State var showFeaturedTabToggleState = false
    @State var showMediaRepliesToggleState = false

    @State var isSavingMediaTabSetting = false
    @State var isSavingMediaRepliesSetting = false
    @State var isSavingFeaturedTabSetting = false
    
    var body: some View {
        List {
            // SHOW/HIDE MEDIA TAB
            Section {
                toggleRow(label: L10nLookup.Scene.EditProfile.TabSettings.mediaTabTitle, subtitle: L10nLookup.Scene.EditProfile.TabSettings.mediaTabSubtitle, toggleState: $showMediaTabToggleState, isSaving: $isSavingMediaTabSetting)
                if showMediaTabToggleState {
                    toggleRow(label: L10nLookup.Scene.EditProfile.TabSettings.includeReplies, subtitle: nil, toggleState: $showMediaRepliesToggleState, isSaving: $isSavingMediaRepliesSetting)
                }
            }
            
            // SHOW/HIDE FEATURED TAB
            Section {
                toggleRow(label: L10nLookup.Scene.EditProfile.TabSettings.featuredTabTitle, subtitle: L10nLookup.Scene.EditProfile.TabSettings.featuredTabSubtitle, toggleState: $showFeaturedTabToggleState, isSaving: $isSavingFeaturedTabSetting)
            } footer: {
                tipText(L10nLookup.Scene.EditProfile.TabSettings.federationDisclaimer)
            }
        }
        .task {
            showMediaTabToggleState = editingViewModel.mediaTabVisibilitySetting == .showMediaTab
            showMediaRepliesToggleState = editingViewModel.mediaTabRepliesSetting == .includeMyRepliesToOthers
            showFeaturedTabToggleState = editingViewModel.featuredTabVisibilitySetting == .showFeaturedTab
        }
        .onChange(of: showMediaTabToggleState) { oldValue, newValue in
            let newSetting: ProfileEditingViewModel.MediaTabVisibilitySetting = newValue ? .showMediaTab : .hideMediaTab
            editingViewModel.setMediaTabVisibilitySetting(newSetting)
            isSavingMediaTabSetting = true
            Task {
                do {
                    try await profileViewModel.commitTabSettingsChanges()
                } catch {
                    navigator.didReceiveError(error)
                }
                isSavingMediaTabSetting = false
            }
        }
        .onChange(of: showMediaRepliesToggleState) { oldValue, newValue in
            let newSetting: ProfileEditingViewModel.MediaTabRepliesSetting = newValue ? .includeMyRepliesToOthers : .showDirectPostsOnly
            editingViewModel.setMediaTabRepliesSetting(newSetting)
            isSavingMediaRepliesSetting = true
            Task {
                do {
                    try await profileViewModel.commitTabSettingsChanges()
                } catch {
                    navigator.didReceiveError(error)
                }
                isSavingMediaRepliesSetting = false
            }
        }
        .onChange(of: showFeaturedTabToggleState) { oldValue, newValue in
            let newSetting: ProfileEditingViewModel.FeaturedTabVisibilitySetting = newValue ? .showFeaturedTab : .hideFeaturedTab
            editingViewModel.setFeaturedTabVisibilitySetting(newSetting)
            isSavingFeaturedTabSetting = true
            Task {
                do {
                    try await profileViewModel.commitTabSettingsChanges()
                } catch {
                    navigator.didReceiveError(error)
                }
                isSavingFeaturedTabSetting = false
            }
        }
            
    }
    
    @ViewBuilder func toggleRow(label: String, subtitle: String?, toggleState: Binding<Bool>, isSaving: Binding<Bool>) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(label)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                if let subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            
            ZStack(alignment: .trailing) {
                if isSaving.wrappedValue {
                    Toggle("", isOn: toggleState)
                        .tint(Asset.Colors.accent.swiftUIColor)
                        .hidden()
                    ProgressView().progressViewStyle(.circular)
                } else {
                    Toggle("", isOn: toggleState) // TODO: A11y
                        .tint(Asset.Colors.accent.swiftUIColor)
                    ProgressView().progressViewStyle(.circular)
                        .hidden()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FeaturedHashtagsEditor: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(FeaturedHashtagsModel.self) var hashtagsModel
    @Environment(MastodonNavigationRouter.self) var navigator
    
    @State var needsDeleteConfirmation: Mastodon.Entity.FeaturedTag?

    var body: some View {
        hashtagsList(hashtagsModel.featuredHashtags)
            .alert(alertTitle,
                   isPresented: Binding<Bool>(
                get: { needsDeleteConfirmation != nil },
                set: { newValue in if newValue == false { needsDeleteConfirmation = nil } }
               )) {
                   Button(L10nLookup.Scene.EditProfile.FeaturedHashtags.remove, role: .destructive) {
                       guard let confirmedForDeletion = needsDeleteConfirmation else { return }
                       Task {
                           do {
                               try await hashtagsModel.removeFeaturedHashtag(confirmedForDeletion)
                           } catch {
                               navigator.didReceiveError(error)
                           }
                       }
                   }
                   
                   Button(L10nLookup.Scene.EditProfile.FeaturedHashtags.keep, role: .cancel) {
                       return
                   }
               }
    }
    
    var alertTitle: String {
        guard let needsDeleteConfirmation else { return "" }
        return L10nLookup.Scene.EditProfile.FeaturedHashtags.removeConfirmation(tagName: needsDeleteConfirmation.name)
    }
    
    @ViewBuilder var addHashtagButton: some View {
        actionButton(text: L10nLookup.Scene.EditProfile.FeaturedHashtags.add, isDestructive: false, includeBackground: false) {
            navigator.presentModal(.editProfileNavigation(destination: .addHashtag(profileViewModel: profileViewModel)))
        }
    }
    
    @ViewBuilder func hashtagsList(_ hashtags: [Mastodon.Entity.FeaturedTag]) -> some View {
        List() {
            if !hashtags.isEmpty {
                Section() {
                    ForEach(hashtags, id: \.self) { hashtag in
                        if hideRowBecauseItIsBeingDeleted(hashtag) {
                            EmptyView()
                        } else {
                            HashtagRow(hashtag: hashtag)
                                .padding(.vertical, doublePadding)
                        }
                    }
                    .onDelete { offsets in
                        needsDeleteConfirmation = hashtagsModel.tagToRemove(basedOnDeletionOffsets: offsets)
                    }
                    .ignoresSafeArea()
                }
            }
            
            Section() {
                addHashtagButton
                    .ignoresSafeArea()
            }
        }
        .listStyle(.insetGrouped)
    }
    
    func hideRowBecauseItIsBeingDeleted(_ featuredTag: Mastodon.Entity.FeaturedTag) -> Bool {
        if needsDeleteConfirmation == featuredTag {
            return true
        } else {
            switch hashtagsModel.currentFetchState {
            case .unfeaturing(let unfeaturing):
                return unfeaturing == featuredTag
            default:
                return false
            }
        }
    }
}

struct AddFeaturedHashtagView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(FeaturedHashtagsModel.self) var featuredHashtagsModel
    @Environment(AutoCompleteSuggestionViewModel.self) var autoCompleteSuggestionsModel
    
    @Environment(\.dismiss) var dismiss
    
    @State var searchText: String = ""
    @State var didFeature: String?
    
    @FocusState var focusSearchField: Bool
    
    var body: some View {
        List() {
            let filteredAutoCompleteSuggestions = filterAutocompleteSuggestions(autoCompleteSuggestionsModel.autoCompleteSuggestions)
            if !filteredAutoCompleteSuggestions.isEmpty {
                ForEach(filteredAutoCompleteSuggestions, id: \.self) { autoCompleteItem in
                    switch autoCompleteItem {
                    case .hashtagV1(let tagName):
                        suggestedHashtagRow(tagName)
                    case .hashtag(let tag):
                        suggestedHashtagRow(tag.name)
                    default:
                        EmptyView()
                    }
                }
            } else if let suggestedTags = featuredHashtagsModel.suggestedTags, !suggestedTags.isEmpty {
                ForEach(suggestedTags, id: \.self) { tag in
                    suggestedHashtagRow(tag.name)
                }
            } else {
                switch featuredHashtagsModel.currentFetchState {
                case .fetchingSuggestedTags:
                    ProgressView().progressViewStyle(.circular)
                default:
                    EmptyView()
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, placement: .navigationBarDrawer)
        .searchFocused($focusSearchField)
        .onChange(of: focusSearchField, { oldValue, newValue in
            if newValue == false && oldValue == true {
                if (featuredHashtagsModel.suggestedTags == nil || featuredHashtagsModel.suggestedTags!.isEmpty) && autoCompleteSuggestionsModel.autoCompleteSuggestions.isEmpty {
                    dismiss()
                }
            }
        })
        .onChange(of: searchText) {
            guard !searchText.isEmpty else {
                autoCompleteSuggestionsModel.foundPossibleHashtag("")
                return
            }
            let withTagSymbol = searchText.first == "#" ? searchText : "#\(searchText)"
            autoCompleteSuggestionsModel.foundPossibleHashtag(withTagSymbol)
        }
        .alert(
            L10nLookup.Scene.EditProfile.FeaturedHashtags.addConfirmedTitle(tagName: didFeature ?? ""),
            isPresented: Binding<Bool>(
                get: { didFeature != nil },
                set: { newValue in if newValue == false { didFeature = nil } }
            ),
            actions: {
                Button(L10nLookup.Scene.EditProfile.FeaturedHashtags.addAnother) {
                    return
                }
                Button(L10n.Common.Controls.Actions.done) {
                    dismiss()
                }
            },
            message: {
                Text(L10nLookup.Scene.EditProfile.FeaturedHashtags.addConfirmedText(tagName: didFeature ?? ""))
            })
        .task(id: profileViewModel.account?.id ?? "unknown_account") {
            guard let account = profileViewModel.account else { return }
            if let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value
                {
                autoCompleteSuggestionsModel.setAuthenticationBox(currentUser)
            }
            do {
                try await featuredHashtagsModel.fetchSuggestedTags(forAccount: account)
                if featuredHashtagsModel.suggestedTags?.isEmpty != true {
                    focusSearchField = true
                }
            } catch {
                navigator.didReceiveError(error)
            }
        }
    }
    
    private func filterAutocompleteSuggestions(_ autoCompleteSuggestions:  [AutoCompleteItem]) ->  [AutoCompleteItem] {
        return autoCompleteSuggestions.filter { item in
            switch item {
            case .hashtag(let tag):
                return !featuredHashtagsModel.featuredHashtags.contains { featuredTag in
                    featuredTag.name == tag.name
                }
            case .hashtagV1(let tagName):
                return !featuredHashtagsModel.featuredHashtags.contains { featuredTag in
                    featuredTag.name == tagName
                }
            default:
                return false
            }
        }
    }
    
    @ViewBuilder func suggestedHashtagRow(_ hashtag: String) -> some View {
        HStack {
            switch featuredHashtagsModel.currentFetchState {
            case .featuring(tagName: hashtag):
                ProgressView().progressViewStyle(.circular)
            default:
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Asset.Colors.accent.swiftUIColor)
            }
            Text("#\(hashtag)")
        }
        .onTapGesture {
            Task {
                try await featuredHashtagsModel.addFeaturedHashtag(tagName: hashtag)
                searchText = ""
                didFeature = hashtag
            }
        }
    }
}


struct CustomProfileFieldsEditor: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    var body: some View {
        List {
            let customFields = editingViewModel.customFields ?? []
            if !customFields.isEmpty {
                Section {
                    customFieldsList(customFields)
                } header: {
                    SubsectionHeading(title: nil, subtitle: L10nLookup.Scene.EditProfile.CustomFields.customFieldPrompt)
                } footer: {
                    verifiedLinksTip
                }
            }
            if editingViewModel.canAddAnotherProfileField {
                Section {
                    actionButton(text: L10nLookup.Scene.EditProfile.CustomFields.addField, isDestructive: false, includeBackground: false) {
                        editingViewModel.beginEditingField(.create, profileViewModel: profileViewModel, navigator: navigator)
                    }
                } header: {
                    if customFields.isEmpty {
                        verifiedLinksTip
                    }
                }
            }
            if !customFields.isEmpty {
                Section {
                    if editingViewModel.canAddAnotherProfileField {
                        actionButton(text: L10nLookup.Scene.EditProfile.CustomFields.reorderFields, isDestructive: false, includeBackground: false) {
                            editingViewModel.beginReorderingFields(profileViewModel: profileViewModel, navigator: navigator)
                        }
                    } else {
                        actionButton(text: L10nLookup.Scene.EditProfile.CustomFields.reorderOrDeleteFields, isDestructive: false, includeBackground: false) {
                            editingViewModel.beginReorderingFields(profileViewModel: profileViewModel, navigator: navigator)
                        }
                    }
                } header: {
                    if let limitReachedMessage = editingViewModel.customFieldLimitReachedMessage {
                        tipText(limitReachedMessage)
                    }
                }
            }
        }
    }
    
    @ViewBuilder var verifiedLinksTip: some View {
        if editingViewModel.showVerifiedLinkTip {
            (Text( L10nLookup.Scene.EditProfile.CustomFields.verifiedLinkTip + "  ")
                .font(.footnote)
             + Text(L10n.Scene.Notification.Warning.learnMore)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(Asset.Colors.accent.swiftUIColor))
            .onTapGesture {
                navigator.presentModal(.editProfileNavigation(destination: .verifiedLinkInstructions(profileViewModel: profileViewModel)))
            }
        }
    }
    
    @ViewBuilder func customFieldsList(_ customFields: [Mastodon.Entity.Field]) -> some View {
        ForEach(customFields, id: \.self) { field in
            customFieldRow(field, emojis: editingViewModel.emojis, isReordering: false)
                .padding(.vertical, doublePadding)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        editingViewModel.beginEditingField(.edit(field), profileViewModel: profileViewModel, navigator: navigator)
                    }
                }
        }
    }
}

struct HashtagRow: View {
    @Environment(FeaturedHashtagsModel.self) var featuredTagsModel
    
    let hashtag: Mastodon.Entity.FeaturedTag
    
    var body: some View {
        HStack {
            Text("#\(hashtag.name)")
                .fixedSize(horizontal: true, vertical: false)
            Spacer()
            switch featuredTagsModel.currentFetchState {
            case .fetchingAll, .unfeaturing(hashtag):
                ProgressView().progressViewStyle(.circular)
            default:
                if let statusesCount = hashtag.statusesCount, let postCount = intFormatter.number(from: statusesCount)?.intValue, postCount > 0 {
                    Text(L10nLookup.Scene.EditProfile.FeaturedHashtags.usedInCountPosts(count: postCount))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

let intFormatter = NumberFormatter()

@ViewBuilder func customFieldRow(_ field: Mastodon.Entity.Field, emojis: [Mastodon.Entity.Emoji], isReordering: Bool) -> some View {
    HStack {
        HStack(alignment: .firstTextBaseline) {
            MastodonContentView.profileEditingRow(html: field.name, emojis: emojis, isLabel: true)
                .fixedSize(horizontal: true, vertical: false)
            Spacer()
            MastodonContentView.profileEditingRow(html: field.value, emojis: emojis, isLabel: false)
                .fixedSize(horizontal: false, vertical: true)
            if field.verifiedAt != nil {
                Asset.Scene.Profile.About.verifiedLinkBadge.swiftUIImage
            }
            if isReordering {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
            }
        }
    }
    .frame(maxWidth: .infinity)
}

struct VerifiedLinkInstructions: View {
    let accountUrl: String?
    
    var body: some View {
        ScrollView() {
            VStack(alignment: .leading, spacing: standardPadding) {
                Text(L10nLookup.Scene.EditProfile.VerifiedLinksExplainer.intro)
                
                // STEP 1:
                HStack(alignment: .top) {
                    Image(systemName: "1.circle")
                        .font(.title2)
                        .foregroundStyle(.primary, .tertiary)
                    VStack(alignment: .leading) {
                        Text(L10nLookup.Scene.EditProfile.VerifiedLinksExplainer.copyTheCodeBelow)
                            .fontWeight(.bold)
                        VStack(alignment: .leading) {
                            let codeSnippet = "<a rel=\"me\" href=\"\(accountUrl ?? "<YOUR_ACCOUNT_URL_GOES_HERE>")\">Mastodon</a>"
                            Text(codeSnippet)
                            Divider()
                            Button() {
                                UIPasteboard.general.string = codeSnippet
                            } label: {
                                Text(L10nLookup.Scene.EditProfile.VerifiedLinksExplainer.copyCode)
                                    .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                            }
                        }
                        .padding()
                        .background() {
                            RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
                                .fill(Asset.Colors.FigmaToken.bgSecondary.swiftUIColor)
                        }
                    }
                }
                
                // STEP 2:
                HStack(alignment: .top) {
                    Image(systemName: "2.circle")
                        .font(.title2)
                        .foregroundStyle(.primary, .tertiary)
                    VStack(alignment: .leading) {
                        Text(L10nLookup.Scene.EditProfile.VerifiedLinksExplainer.pasteCode)
                            .fontWeight(.bold)
                        Text(L10nLookup.Scene.EditProfile.VerifiedLinksExplainer.explanation)
                    }
                }
                
                // STEP 3:
                HStack(alignment: .top) {
                    Image(systemName: "3.circle")
                        .font(.title2)
                        .foregroundStyle(.primary, .tertiary)
                    VStack(alignment: .leading) {
                        Text(L10nLookup.Scene.EditProfile.VerifiedLinksExplainer.addWebsiteAsCustomField)
                            .fontWeight(.bold)
                        Text(L10nLookup.Scene.EditProfile.VerifiedLinksExplainer.addWebsiteDetailExplainer)
                    }
                }
                Spacer()
            }
        }
    }
}

struct EditFieldView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    @Environment(MastodonNavigationRouter.self) var navigator
    
    @Environment(\.dismiss) var dismiss
    
    @FocusState var focusedField: FocusableField?
    
    @State var labelContentHasChanged: Bool = false
    @State var valueContentHasChanged: Bool = false
    
    let labelWidth: CGFloat = 100
    
    enum FocusableField {
        case label
        case value
    }
    
    var body: some View {
        List {
            if let editState = editingViewModel.fieldEditingState {
                @Bindable var labelEditingModel = editState.labelEditingModel
                @Bindable var valueEditingModel = editState.valueEditingModel
                Section {
                    HStack(alignment: .top, spacing: tinySpacing) {
                        Text(L10nLookup.Scene.EditProfile.CustomFields.label)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: labelWidth, alignment: .leading)
                        VStack(alignment: .leading) {
                            TextField("", text: $labelEditingModel.stringContent)
                                .focused($focusedField, equals: .label)
                            if focusedField == .label && labelContentHasChanged {
                                CharacterLimitTip(showCounterOnly: true)
                                    .environment(labelEditingModel)
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .onAppear() {
                        switch editState.editingField {
                        case .create:
                            focusedField = .label
                        case .edit:
                            break
                        }
                    }
                    .onChange(of: editState.labelEditingModel.stringContent) { oldValue, newValue in
                        if !labelContentHasChanged {
                            labelContentHasChanged = true
                        }
                        profileViewModel.checkForEditingChanges()
                        if newValue.last == "\n" {
                            focusedField = .value
                            profileViewModel.checkForEditingChanges()
                        }
                    }
                    
                    HStack(alignment: .top, spacing: tinySpacing) {
                        Text(L10nLookup.Scene.EditProfile.CustomFields.value)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: labelWidth, alignment: .leading)
                        VStack(alignment: .leading) {
                            TextField("", text: $valueEditingModel.stringContent)
                                .focused($focusedField, equals: .value)
                            if focusedField == .value && valueContentHasChanged {
                                CharacterLimitTip(showCounterOnly: true)
                                    .environment(valueEditingModel)
                            }
                        }
                    }
                    .onChange(of: editState.valueEditingModel.stringContent) { oldValue, newValue in
                        if !valueContentHasChanged {
                            valueContentHasChanged = true
                        }
                        profileViewModel.checkForEditingChanges()
                        if newValue.last == "\n" {
                            focusedField = nil
                            profileViewModel.checkForEditingChanges()
                        }
                    }
                } footer: {
                    tipText(L10nLookup.Scene.EditProfile.CustomFields.characterCountTip)
                }
                
                switch editState.editingField {
                case .create:
                    EmptyView()
                case .edit:
                    Section {
                        actionButton(text: L10nLookup.Scene.EditProfile.CustomFields.deleteField, isDestructive: true, includeBackground: false) {
                            Task {
                                editingViewModel.deleteCurrentEditingField()
                                do {
                                    try await profileViewModel.commitEdits()
                                    dismiss()
                                } catch {
                                    navigator.didReceiveError(error)
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    ProgressView().progressViewStyle(.circular)
                }
            }
        }
    }
}

struct ReorderCustomFieldsView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    var body: some View {
        @Bindable var editingViewModel = editingViewModel
        List {
            ForEach($editingViewModel.reorderingCustomFields, id: \.self, editActions: .all) { $field in
                customFieldRow(field, emojis: editingViewModel.emojis, isReordering: true)
                    .padding(.vertical, doublePadding)
            }
            .onChange(of: editingViewModel.reorderingCustomFields) { oldValue, newValue in
                profileViewModel.checkForEditingChanges()
            }
            .ignoresSafeArea()
        }.listStyle(.insetGrouped)
    }
}

@ViewBuilder func actionButton(text: String, isDestructive: Bool, includeBackground: Bool = true, action: @escaping ()->()) -> some View {
    Button() {
        action()
    } label: {
        Text(text)
            .foregroundStyle(isDestructive ? .red : Asset.Colors.accent.swiftUIColor)
            .padding(includeBackground ? doublePadding : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background() {
                if includeBackground {
                    Capsule()
                        .fill(Asset.Colors.FigmaToken.bgSecondary.swiftUIColor)
                }
            }
    }
}

@ViewBuilder func tipText(_ text: String) -> some View {
    Text(text)
        .font(.footnote)
}
