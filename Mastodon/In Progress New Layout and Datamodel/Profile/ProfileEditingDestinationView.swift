// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonSDK
import MastodonUI

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

struct ProfileEditingDestinationView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let destinationType: ProfileEditDestinationType
    
    var body: some View {
        if destinationType.expectsModalPresentation {
            NavigationStack() {
                rootContents
                    .padding(doublePadding)
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
            rootContents
                .padding(doublePadding)
                .navigationTitle(profileViewModel.navigationTitle(destinationType))
                .navigationBarTitleDisplayMode(.inline)
        }
      
    }
    
    @ViewBuilder var rootContents: some View {
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
                .environment(editingViewModel)
        case .profileTabSettings:
            ProfileTabSettingsEditor()
                .environment(editingViewModel)
        case .verifiedLinkInstructions(let profileViewModel):
            let accountUrl = profileViewModel.account?.metadata.profileUrl?.absoluteString
            VerifiedLinkInstructions(accountUrl: accountUrl)
        case .editCustomField(let profileViewModel):
            EditFieldView()
                .environment(profileViewModel.editingViewModel)
        }
    }
}

extension ProfileViewModel {
    func navigationTitle(_ destination: ProfileEditDestinationType) -> String {
        // TODO: L10n
        switch destination {
        case .displayName:
            return "Edit display name"
        case .bio:
            if bioIsEmpty {
                return "Add bio"
            } else {
                return "Edit bio"
            }
        case .customFields:
            return "Custom fields"
        case .featuredHashtags:
            return "Featured hashtags"
        case .profileTabSettings:
            return "Profile tab settings"
        case .verifiedLinkInstructions:
            return "How to add a verified link"
        case .editCustomField(let profileViewModel):
            guard let fieldEditingState = profileViewModel.editingViewModel.fieldEditingState else { return "" }
            switch fieldEditingState.editingField {  // TODO: L10n
            case .create:
                return "Add field"
            case .edit:
                return "Edit field"
            }
        }
    }
}

struct EditSingleTextView: View {
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    @Environment(MetaTextInputFieldViewModel.self) var textInputModel
    
    @FocusState var isFocused: Bool
    
    let allowTextScroll: Bool
    let textViewHeight: CGFloat
    let returnKeyType: UIReturnKeyType
    
    var body: some View {
        VStack(alignment: .leading, spacing: tinySpacing) {
            MetaTextInputField(allowScroll: allowTextScroll, drawBackground: false, returnKeyType: returnKeyType)
                .frame(height: textViewHeight)
                .focused($isFocused)
            CharacterLimitTip()
                .padding(.leading)
            Spacer()
        }
        .onAppear() {
            isFocused = true
        }
        .onChange(of: textInputModel.stringContent) { oldValue, newValue in
            if newValue.last == "\n" {
                isFocused = false
                editingViewModel.checkForChanges()
            }
        }
    }
}

struct CharacterLimitTip: View {
    @Environment(MetaTextInputFieldViewModel.self) var inputModel
    
    var body: some View {
        Text(message(forCharacterCount: inputModel.characterCount))
            .font(.footnote)
            .foregroundStyle(characterLimit - inputModel.characterCount < 0 ? overLimitColor : .secondary)
    }
    
    func message(forCharacterCount usedCharacterCount: Int) -> String {
        // TODO: L10n
        switch inputModel.characterLimit {
        case .hardLimit(let limit):
            if inputModel.characterCount == 0 {
                "\(limit) character maximum"
            } else {
                "\(usedCharacterCount)/\(characterLimit) characters"
            }
        case .softLimit(let limit):
            "Tip: try to keep this short, under \(limit) characters is best"
        }
    }
    
    var characterLimit: Int {
        switch inputModel.characterLimit {
        case .hardLimit(let limit), .softLimit(let limit):
            return limit
        }
    }
    
    var overLimitColor: Color {
        switch inputModel.characterLimit {
        case .hardLimit:
                .red
        case .softLimit:
                .yellow
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
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: doublePadding) {
            VStack(alignment: .leading) {
                ProfileSectionHeader(section: .displayPreferences)
                infoButton(.displayPreferences)
            }
            
            // SHOW/HIDE MEDIA TAB
            VStack(alignment: .leading) {
                SubsectionHeading(title: "’Media’ tab settings", subtitle: "‘Media’ is an optional tab that shows your posts containing images or videos.")
                RadioButtonArray(items: [(ProfileEditingViewModel.MediaTabVisibilitySetting.showMediaTab.rawValue, "Show ‘Media’ tab"), (ProfileEditingViewModel.MediaTabVisibilitySetting.hideMediaTab.rawValue, "Hide ‘Media’ tab")], selectedItem: Binding<Int>(
                    get: { editingViewModel.mediaTabVisibilitySetting.rawValue },
                    set: { newValue in
                        guard newValue != editingViewModel.mediaTabVisibilitySetting.rawValue else { return }
                        editingViewModel.setMediaTabVisibilitySetting(.init(rawValue: newValue) ?? .showMediaTab)
                        Task {
                            try await profileViewModel.commitTabSettingsChanges()
                        }
                    }
                ))
            }
            
            // INCLUDE REPLIES ON MEDIA TAB
            VStack(alignment: .leading) {
                SubsectionHeading(title: "Include replies on ’Media’ tab?", subtitle: nil)
                RadioButtonArray(items: [(ProfileEditingViewModel.MediaTabRepliesSetting.showDirectPostsOnly.rawValue, "Only show my posts"), (ProfileEditingViewModel.MediaTabRepliesSetting.includeMyRepliesToOthers.rawValue, "Show my posts and replies to other people's posts")], selectedItem: Binding<Int>(
                    get: { editingViewModel.mediaTabRepliesSetting.rawValue },
                    set: { newValue in
                        guard newValue != editingViewModel.mediaTabRepliesSetting.rawValue else { return }
                        editingViewModel.setMediaTabRepliesSetting(.init(rawValue: newValue) ?? .showDirectPostsOnly)
                        Task {
                            try await profileViewModel.commitTabSettingsChanges()
                        }
                    }
                ))
            }
            
            // FEATURED TAB SETTINGS
            VStack(alignment: .leading) {
                SubsectionHeading(title: "’Featured’ tab settings", subtitle: "’Featured’ is an optional tab where you can showcase other accounts and collections.")
                RadioButtonArray(items: [(ProfileEditingViewModel.FeaturedTabVisibilitySetting.showFeaturedTab.rawValue, "Show ’Featured’ tab"), (ProfileEditingViewModel.FeaturedTabVisibilitySetting.hideFeaturedTab.rawValue, "Hide ’Featured’ tab")], selectedItem: Binding<Int>(
                    get: { editingViewModel.featuredTabVisibilitySetting.rawValue },
                    set: { newValue in
                        guard newValue != editingViewModel.featuredTabVisibilitySetting.rawValue else { return }
                        editingViewModel.setFeaturedTabVisibilitySetting(.init(rawValue: newValue) ?? .showFeaturedTab)
                        Task {
                            try await profileViewModel.commitTabSettingsChanges()
                        }
                    }
                ))
            }
        }
    }
}

struct FeaturedHashtagsEditor: View {
    
    var body: some View {
        // FEATURED HASHTAGS
        
        HStack {
            SubsectionHeading(title: "Featured hashtags", subtitle: "Help others identify, and have quick access to, your favorite topics")
            HStack {
                Text("Manage")
                Image(systemName: "chevron.forward")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        .onTapGesture {
        }
    }
}

struct CustomProfileFieldsEditor: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    var body: some View {
        // TODO: L10n
        ScrollView() {
            VStack(alignment: .leading, spacing: doublePadding) {
                SubsectionHeading(title: nil, subtitle: "Add your pronouns, external links, or anything else you’d like to share.")
                if let customFields = editingViewModel.customFields, !customFields.isEmpty {
                    customFieldsList(customFields)
                }
                actionButton(text: "Add field", isDestructive: false) {
                    editingViewModel.beginEditingField(.create, profileViewModel: profileViewModel, navigator: navigator)
                }
                if let customFields = editingViewModel.customFields, !customFields.isEmpty {
                    actionButton(text: "Reorder fields", isDestructive: false) {
                    }
                }
                if editingViewModel.showVerifiedLinkTip {
                    (Text("Tip: Add credibility to your Mastodon account by verifying links to websites you own.  ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                     + Text("Learn more")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(Asset.Colors.accent.swiftUIColor))
                    .onTapGesture {
                        navigator.presentModal(.editProfileNavigation(destination: .verifiedLinkInstructions(profileViewModel: profileViewModel)))
                    }
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder var verifiedLinksTipBox: some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.seal")
                .font(.subheadline)
                .padding(tinySpacing)
                .background() {
                    Circle()
                        .fill(brandBackgroundColor)
                }
            
            VStack(alignment: .leading) {
                Spacer()
                    .frame(height: tinySpacing)
                Text("Tip: Adding verified links")
                    .fontWeight(.semibold)
                Text("You can easily add credibility to your Mastodon account by verifying links to any websites you own.")
            }
            .font(.subheadline)
            
            Button() {
                withAnimation {
                    editingViewModel.showVerifiedLinkTip = false
                }
            } label: {
                Image(systemName: "xmark")
            }
        }
        .padding()
        .background() {
            RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
                .fill(brandBackgroundColor)
        }
    }
    
    @ViewBuilder func customFieldsList(_ customFields: [Mastodon.Entity.Field]) -> some View {
        VStack {
            ForEach(customFields, id: \.self) { field in
                customFieldRow(field)
                    .padding(.vertical, doublePadding)
                    .onTapGesture {
                        withAnimation {
                            editingViewModel.beginEditingField(.edit(field), profileViewModel: profileViewModel, navigator: navigator)
                        }
                    }
                if customFields.firstIndex(where: { $0.hashValue == field.hashValue }) != customFields.endIndex - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, doublePadding)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
                .fill(Asset.Colors.FigmaToken.bgSecondary.swiftUIColor)
        }
    }
    
    @ViewBuilder func customFieldRow(_ field: Mastodon.Entity.Field) -> some View {
        HStack {
            HStack(alignment: .firstTextBaseline) {
                MastodonContentView.profileEditingRow(html: field.name, emojis: editingViewModel.emojis, isLabel: true)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer()
                MastodonContentView.profileEditingRow(html: field.value, emojis: editingViewModel.emojis, isLabel: false)
                    .fixedSize(horizontal: false, vertical: true)
                if field.verifiedAt != nil {
                    Asset.Scene.Profile.About.verifiedLinkBadge.swiftUIImage
                }
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct VerifiedLinkInstructions: View {
    let accountUrl: String?
    
    var body: some View {
        // TODO: L10n
        ScrollView() {
            VStack(alignment: .leading, spacing: standardPadding) {
                Text("Add credibility to your Mastodon profile by verifying links to personal websites. Here’s how it works:")
                
                // STEP 1:
                HStack(alignment: .top) {
                    Image(systemName: "1.circle")
                        .font(.title2)
                        .foregroundStyle(.primary, .tertiary)
                    VStack(alignment: .leading) {
                        Text("Copy the HTML code below")
                            .fontWeight(.bold)
                        VStack(alignment: .leading) {
                            let codeSnippet = "<a rel=\"me\" href=\"\(accountUrl ?? "<YOUR_ACCOUNT_URL_GOES_HERE>")\">Mastodon</a>"
                            Text(codeSnippet)
                            Divider()
                            Button() {
                                UIPasteboard.general.string = codeSnippet
                            } label: {
                                Text("Copy code")
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
                        Text("Paste the code into the header HTML of your website")
                            .fontWeight(.bold)
                        Text("Adding the code to your header allows the <a> element to remain invisible. The rel=\"me\" attribute prevents impersonation on websites with user-generated content – so it’s important to keep it.")
                    }
                }
                
                // STEP 3:
                HStack(alignment: .top) {
                    Image(systemName: "3.circle")
                        .font(.title2)
                        .foregroundStyle(.primary, .tertiary)
                    VStack(alignment: .leading) {
                        Text("Add your website as a custom field")
                            .fontWeight(.bold)
                        Text("If you’ve already added your website as a custom field, you’ll need to delete and re-add it to trigger verification.")
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
    
    let labelWidth: CGFloat = 100
    
    enum FocusableField {
        case label
        case value
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: doublePadding) {
            if let editState = editingViewModel.fieldEditingState {
                HStack(spacing: tinySpacing) {
                    Text("Label") // TODO: L10n
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: labelWidth, alignment: .leading)
                        .frame(maxHeight: .infinity)
                    MetaTextInputField(allowScroll: false, drawBackground: false, returnKeyType: .next)
                        .fixedSize(horizontal: false, vertical: false)
                        .environment(editState.labelEditingModel)
                        .focused($focusedField, equals: .label)
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
                    editingViewModel.checkForChanges()
                    if newValue.last == "\n" {
                        focusedField = .value
                        editingViewModel.checkForChanges()
                    }
                }
                
                Divider()
                
                HStack(spacing: tinySpacing) {
                    Text("Value") // TODO: L10n
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: labelWidth, alignment: .leading)
                    MetaTextInputField(allowScroll: true, drawBackground: false, returnKeyType: .done)
                        .frame(maxHeight: 50)
                        .environment(editState.valueEditingModel)
                        .focused($focusedField, equals: .value)
                }
                .onChange(of: editState.valueEditingModel.stringContent) { oldValue, newValue in
                    editingViewModel.checkForChanges()
                    if newValue.last == "\n" {
                        focusedField = nil
                        editingViewModel.checkForChanges()
                    }
                }
                
                tipText("Tip: Try to keep the label and value short (under 25 characters for each is best).")  // TODO: L10n
                
                switch editState.editingField {
                case .create:
                    EmptyView()
                case .edit:
                    actionButton(text: "Delete field", isDestructive: true) {  // TODO: L10n
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
                
                Spacer()
            }
            else {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            }
        }
    }
}

@ViewBuilder func actionButton(text: String, isDestructive: Bool, action: @escaping ()->()) -> some View {
    Button() {
        action()
    } label: {
        Text(text)
            .foregroundStyle(isDestructive ? .red : Asset.Colors.accent.swiftUIColor)
            .padding(doublePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background() {
                Capsule()
                    .fill(Asset.Colors.FigmaToken.bgSecondary.swiftUIColor)
            }
    }
}

@ViewBuilder func tipText(_ text: String) -> some View {
    Text(text)
        .font(.footnote)
        .foregroundStyle(.secondary)
}
