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
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let destinationType: ProfileEditDestinationType
    
    var body: some View {
        if destinationType.expectsModalPresentation {
            NavigationStack() {
                rootContents
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
                .environment(editingViewModel)
        case .featuredHashtags:
            FeaturedHashtagsEditor()
                .environment(editingViewModel)
        case .profileTabSettings:
            ProfileTabSettingsEditor()
                .environment(editingViewModel)
        }
    }
}

extension ProfileViewModel {
    func navigationTitle(_ destination: ProfileEditDestinationType) -> String {
        // TODO: L10n
        switch destination {
        case .displayName:
            "Edit display name"
        case .bio:
            if bioIsEmpty {
                "Add bio"
            } else {
                "Edit bio"
            }
        case .customFields:
            "Custom fields"
        case .featuredHashtags:
            "Featured hashtags"
        case .profileTabSettings:
            "Profile tab settings"
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
        .padding(doublePadding)
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
        case .displayName(profileViewModel: let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.displayNameFieldEditingViewModel.discardChanges()
        case .bio(profileViewModel: let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.bioFieldEditingViewModel.discardChanges()
        case .customFields(profileViewModel: let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.discardCustomFieldEdits()
        case .featuredHashtags(profileViewModel: let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            editingViewModel.discardFeaturedHashtagEdits()
        case .profileTabSettings(profileViewModel: let profileViewModel):
            assert(profileViewModel.uuid == uuid)
            assertionFailure("profile tab setting changes are saved immediately and cannot be discarded")
        }
    }
}

extension ProfileEditingViewModel {
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
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    @State private var draggingField: Mastodon.Entity.Field?
    
    var body: some View {
        VStack(alignment: .leading) {
            ProfileSectionHeader(section: .customFields)
            infoButton(.customFields)
            SubsectionHeading(title: nil, subtitle: "Add your pronouns, external links, or anything else you’d like to share.") // TODO: needs L10n
            if let customFields = editingViewModel.customFields, !customFields.isEmpty {
                customFieldsList(customFields)
                Divider()
            }
            addFieldButton
            if editingViewModel.showVerifiedLinkTip {
                verifiedLinksTipBox
            }
        }
    }
    
    @ViewBuilder var addFieldButton: some View {
        Button() {
            withAnimation {
                editingViewModel.beginEditingField(.create)
            }
        } label: {
            HStack(spacing: tinySpacing) {
                Image(systemName: "plus")
                Text("Add a field") // TODO: needs L10n
            }
            .font(.subheadline)
            .padding(.vertical, tinySpacing)
            .padding(.horizontal, standardPadding)
            .background() {
                Capsule()
                    .fill(.quinary)
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
                customFieldRow(field, isDraggable: false)
                    .onTapGesture {
                        withAnimation {
                            editingViewModel.beginEditingField(.edit(field))
                        }
                    }
            }
        }
    }
    
    @ViewBuilder func customFieldRow(_ field: Mastodon.Entity.Field, isDraggable: Bool, isDragging: Bool) -> some View {
        if isDragging {
            customFieldRow(field, isDraggable: isDraggable)
                .hidden()
        } else {
            customFieldRow(field, isDraggable: isDraggable)
        }
    }
    
    @ViewBuilder func customFieldRow(_ field: Mastodon.Entity.Field, isDraggable: Bool) -> some View {
        HStack {
            if isDraggable {
                Image(systemName: "line.3.horizontal")
            }
            
            VStack(alignment: .leading) {
                Text(field.name)
                    .fixedSize(horizontal: false, vertical: true)
                MastodonContentView.customProfileField(html: field.value, emojis: editingViewModel.emojis, bold: true, lineLimit: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.footnote)
            
            Spacer()
            
            Button() {
                withAnimation {
                    editingViewModel.requestDeleteCustomField(field)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(standardPadding)
                    .background() {
                        Circle()
                            .stroke(.quaternary)
                    }
            }
        }
        .padding()
    }
}
