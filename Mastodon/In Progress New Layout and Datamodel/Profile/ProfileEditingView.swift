// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import PhotosUI
import SwiftUI
import MastodonUI
import MastodonLocalization
import MastodonAsset
import MastodonSDK
import MastodonCore
import Kanna // for stripping the html from the account bio

class ProfileEditHostingViewController: UIHostingController<AnyView> {
    private let viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel, navigator: MastodonNavigationRouter) {
        self.viewModel = viewModel
        super.init(rootView: AnyView(ProfileEditingView().environment(viewModel).environment(viewModel.editingViewModel).environment(navigator)))
            
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum ProfileEditDestinationType: Identifiable {
    case displayName
    case bio
    case customFields(profileViewModel: ProfileViewModel, editingViewModel: ProfileEditingViewModel)
    case featuredHashtags(profileViewModel: ProfileViewModel, editingViewModel: ProfileEditingViewModel)
    case profileTabSettings(profileViewModel: ProfileViewModel, editingViewModel: ProfileEditingViewModel)
    
    var id: String {
        switch self {
        case .displayName:
            "display_name"
        case .bio:
            "bio"
        case .customFields:
            "custom_fields"
        case .featuredHashtags:
            "featured_hashtags"
        case .profileTabSettings:
            "profile tab settings"
        }
    }
    
    var editingViewModel: ProfileEditingViewModel? {
        switch self {
        case .displayName, .bio:
            return nil
        case .customFields(_, let editingViewModel), .featuredHashtags(_, let editingViewModel), .profileTabSettings(_, let editingViewModel):
            return editingViewModel
        }
    }
    
    var profileViewModel: ProfileViewModel? {
        switch self {
        case .displayName, .bio:
            return nil
        case .customFields(let profileViewModel, _), .featuredHashtags(let profileViewModel, _), .profileTabSettings(let profileViewModel, _):
            return profileViewModel
        }
    }
}

extension ProfileEditDestinationType {
    var expectsModalPresentation: Bool {
        switch self {
        case .displayName, .bio:
            true
        case .customFields, .featuredHashtags, .profileTabSettings:
            false
        }
    }
}

struct ProfileEditingView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    var body: some View {
        @Bindable var navigationRouter = navigator
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: standardPadding) {
                    ProfileAvatarAndBannerView(width: geo.size.width)
                    ForEach(allEditRows, id: \.id) { destination in
                        profileEditRow(destination)
                            .padding(.horizontal, doublePadding)
                            .frame(width: geo.size.width)
                            .onTapGesture {
                                navigate(to: destination)
                            }
                    }
                }
            }
        }
    }
    
    var allEditRows: [ProfileEditDestinationType] {
        [
            .displayName,
            .bio,
            .customFields(profileViewModel: profileViewModel, editingViewModel: editingViewModel),
            .featuredHashtags(profileViewModel: profileViewModel, editingViewModel: editingViewModel),
            .profileTabSettings(profileViewModel: profileViewModel, editingViewModel: editingViewModel)
        ]
    }
    
    func navigate(to editDestination: ProfileEditDestinationType) {
        if editDestination.expectsModalPresentation {
            // TODO: implement
        } else {
            navigator.push(.editProfileNavigation(editDestination))
        }
    }
    
    func profileEditRow(_ destination: ProfileEditDestinationType) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(mainLabelForRow(destination))
                    .lineLimit(1)
                    .foregroundColor(mainLabelColorForRow(destination))
                if let subtitle = subtitleForRow(destination) {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            contentForRow(destination)
            disclosureIndicator(destination)
        }
        .padding()
        .background {
            Capsule()
                .fill(Asset.Colors.FigmaToken.bgSecondary.swiftUIColor)
        }
    }
    
    func mainLabelColorForRow(_ destination: ProfileEditDestinationType) -> Color {
        switch destination {
        case .bio:
            profileViewModel.bioIsEmpty ? Asset.Colors.accent.swiftUIColor : .primary
        default:
            .primary
        }
    }
    
    func mainLabelForRow(_ destination: ProfileEditDestinationType) -> String {
        // TODO: L10n
        switch destination {
        case .displayName:
            return "Display name"
        case .bio:
            if profileViewModel.bioIsEmpty {
                return "Add a bio"
            } else {
                return "Bio"
            }
        case .customFields:
            return "Custom fields"
        case .featuredHashtags:
            return "Featured hashtags"
        case .profileTabSettings:
            return "Profile tab settings"
        }
    }
    
    func subtitleForRow(_ destination: ProfileEditDestinationType) -> String? {
        switch destination {
        case .displayName:
            return nil
        case .bio:
            return nil
        case .customFields:
            return "E.g. pronouns, external links, etc."
        case .featuredHashtags:
            return "Allow users to filter your timeline by topic"
        case .profileTabSettings:
            return nil
        }
    }
    
    @ViewBuilder func disclosureIndicator(_ destination: ProfileEditDestinationType) -> some View {
        switch destination {
        case .bio:
            if profileViewModel.bioIsEmpty {
                EmptyView()
            } else {
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
            }
        default:
            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder func contentForRow(_ destination: ProfileEditDestinationType) -> some View {
        switch destination {
        case .displayName:
            if let displayName = profileViewModel.account?.displayInfo.displayName {
                MastodonContentView.profileEditingRowContent(html: displayName, emojis: profileViewModel.account?.displayInfo.emojis ?? [])
            } else {
                Spacer()
            }
        case .bio:
            if profileViewModel.bioIsEmpty {
                Spacer()
            } else if let bio = profileViewModel.account?.bioForDisplay {
                MastodonContentView.profileEditingRowContent(html: bio, emojis: profileViewModel.account?.displayInfo.emojis ?? [])
            }
        case .customFields:
            Text("\(profileViewModel.account?.metadata.customFieldsForEdit?.count ?? 0)")
                .foregroundStyle(.secondary)
        case .featuredHashtags:
            if profileViewModel.featuredHashtagsModel.isFetching {
                ProgressView().progressViewStyle(.circular)
            } else {
                Text("\(profileViewModel.featuredHashtagsModel.featuredHashtags.count)")
                    .foregroundStyle(.secondary)
            }
        case .profileTabSettings:
            Spacer()
        }
    }
}

struct ORIGINALProfileEditingView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    enum FieldEditType {
        case create
        case edit(Mastodon.Entity.Field)
        
        var title: String {
            switch self {
            case .create:
                "Create custom field" // TODO: L10n
            case .edit:
                "Edit custom field" // TODO: L10n
            }
        }
    }
    
    struct FieldEditingState {
        let editingField: FieldEditType
        let labelEditingModel: MetaTextInputFieldViewModel
        let valueEditingModel: MetaTextInputFieldViewModel
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ProfileAvatarAndBannerView(width: geo.size.width)
                    
                    nameAndBio
                        .padding(.horizontal)
                        .padding(.vertical, doublePadding)
                    
                    Divider()
                    
                    CustomProfileFieldsEditor()
                        .padding(.horizontal)
                        .padding(.vertical, doublePadding)
                    
                    Divider()
                    
                    if editingViewModel.showTabDisplayPreferences {
                        DisplayPreferencesEditor()
                            .padding(.horizontal)
                            .padding(.vertical, doublePadding)
                        
                        Divider()
                    }
                    
                    // ADVANCED SETTINGS
                    
                    AdvancedSettingsEditor()
                        .padding(.horizontal)
                        .padding(.vertical, doublePadding)
                    
                    Spacer()
                        .frame(maxHeight: .infinity)
                }
                .overlay {
                    if editingViewModel.bioFieldEditingViewModel.isEditing {
                        editingViewModel.bioFieldEditingViewModel.autoCompleteSuggestionView(pinToTopOfKeyboard: true)
                    } else if profileViewModel.editingStatus.showActivityIndicator {
                        ZStack {
                            Color.dimmingBackground
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
                .sheet(isPresented: editingViewModel.showCroppingView) {
                    if let image = editingViewModel.avatarImageToCrop {
                        PhotoCropperView(originalImage: image) { confirmedImage in
                            defer {
                                self.editingViewModel.avatarImageToCrop = nil
                            }
                            
                            guard let confirmedImage else {
                                self.editingViewModel.avatarConfirmedCroppedImage = nil
                                return
                            }
                            
                            self.editingViewModel.avatarConfirmedCroppedImage = confirmedImage
                        }
                    }
                }
            }
        }
        .navigationTitle(L10nLookup.Scene.EditProfile.title)
        .toolbar {
            saveButtonForToolbar
        }
        .overlay() {
            if let fieldEditingState = editingViewModel.fieldEditingState {
                editFieldView(fieldEditingState)
            }
        }
        .alert(editingViewModel.presentingAlert?.title ?? "",
               isPresented: Binding<Bool>(
                get: { editingViewModel.presentingAlert != nil },
                set: { newValue in
                    if newValue == false {
                        editingViewModel.presentingAlert = nil
                    }
                }
               ),
               actions: {
            Button(role: .cancel) {
                withAnimation {
                    editingViewModel.cancelDeleteCustomField()
                }
            } label: {
                Text("Cancel")
            }
            Button(role: .destructive) {
                withAnimation {
                    editingViewModel.confirmDeleteCustomField()
                }
            } label: {
                Text("Delete")
            }
        },
               message: {
            if let messageText = editingViewModel.presentingAlert?.messageText {
                Text(messageText)
            }
        })
        .onChange(of: editingViewModel.isAutomatedAccount) {
            editingViewModel.checkForChanges()
        }
        .onChange(of: editingViewModel.avatarConfirmedCroppedImage) {
            editingViewModel.checkForChanges()
        }
        .onChange(of: editingViewModel.confirmedBannerImage) {
            editingViewModel.checkForChanges()
        }
        .onChange(of: editingViewModel.mediaTabVisibilitySetting) {
            editingViewModel.checkForChanges()
        }
        .onChange(of: editingViewModel.mediaTabRepliesSetting) {
            editingViewModel.checkForChanges()
        }
        .onChange(of: editingViewModel.featuredTabVisibilitySetting) {
            editingViewModel.checkForChanges()
        }
    }
    
    @ViewBuilder var nameAndBio: some View {
        VStack(spacing: doublePadding) {
            VStack(alignment: .leading, spacing: tinySpacing) {
                SubsectionHeading(title: "Display name", subtitle: nil) // TODO: needs L10n
                MetaTextInputField(allowScroll: false)
                    .environment(editingViewModel.displayNameFieldEditingViewModel)
                    .frame(height: 36)
            }
            
            VStack(alignment: .leading, spacing: tinySpacing) {
                SubsectionHeading(title: "Bio", subtitle: "Introduce yourself. Recommended 220 character maximum.") // TODO: needs L10n
                MetaTextInputField(allowScroll: true)
                    .environment(editingViewModel.bioFieldEditingViewModel)
                    .frame(height: 56)
            }
        }
    }
    
    @ViewBuilder func editFieldView(_ editState: ORIGINALProfileEditingView.FieldEditingState) -> some View {
        GeometryReader { _ in
            ZStack {
                Color.dimmingBackground
                    .onTapGesture {
                        self.editingViewModel.fieldEditingState = nil
                    }
                
                VStack(alignment: .leading, spacing: doublePadding) {
                    Text(editState.editingField.title)
                        .fontWeight(.semibold)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: tinySpacing) {
                        SubsectionHeading(title: "Label", subtitle: nil)
                        MetaTextInputField(allowScroll: false)
                            .environment(editState.labelEditingModel)
                            .frame(height: 36)
                    }
                    
                    VStack(alignment: .leading, spacing: tinySpacing) {
                        SubsectionHeading(title: "Value", subtitle: nil)
                        MetaTextInputField(allowScroll: true)
                            .environment(editState.valueEditingModel)
                            .frame(height: 36)
                    }
                    
                    HStack {
                        Spacer()
                            .frame(maxWidth: .infinity)
                        
                        Button() {
                            withAnimation {
                                editingViewModel.fieldEditingState = nil
                            }
                        } label: {
                            Text("Cancel")
                                .padding(.horizontal)
                                .padding(.vertical, tinySpacing)
                                .background() {
                                    Capsule()
                                        .stroke(.secondary)
                                }
                        }
                        
                        Button() {
                            withAnimation {
                                editingViewModel.commitEditingField()
                            }
                        } label: {
                            Text("Save") // TODO: L10n
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.vertical, tinySpacing)
                                .background() {
                                    Capsule()
                                        .fill(Asset.Colors.accent.swiftUIColor)
                                }
                        }
                    }
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: 300)
                .padding(doublePadding)
                .background() {
                    RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
                        .fill(.background)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    @ViewBuilder func alertContents(_ alert: ProfileEditingViewModel.ProfileEditingAlert) -> some View {
        Color.red
            .frame(width: 200, height: 50)
    }
    
    @ToolbarContentBuilder var saveButtonForToolbar: some ToolbarContent {
        if profileViewModel.editingStatus.showSaveButton {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.Common.Controls.Actions.save) {
                    profileViewModel.editingStatus = .pushingChanges(success: nil)
                    Task {
                        do {
                            try await profileViewModel.commitEdits()
                            profileViewModel.editingStatus = .pushingChanges(success: true)
                        } catch {
                            profileViewModel.editingStatus = .pushingChanges(success: false)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Asset.Colors.accent.swiftUIColor)
            }
        }
    }
}

@MainActor
@Observable
class ProfileEditingViewModel {
    var editingStatusBinding: Binding<EditingStatus>?
    var showVerifiedLinkTip = true
    var showTabDisplayPreferences = false
    
    let displayNameFieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: "", characterLimit: .softLimit(100), autocompleteMastodonItems: false)
    let bioFieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: "Describe yourself and/or this account.", characterLimit: .softLimit(220), autocompleteMastodonItems: true)
    
    var fieldEditingState: ORIGINALProfileEditingView.FieldEditingState?
    
    var selectedBannerImage: Binding<[PhotosPickerItem]>
    var bannerImagePhotosPickerItem: PhotosPickerItem?
    var confirmedBannerImage: UIImage?
    
    var selectedAvatar: Binding<[PhotosPickerItem]>
    var avatarPhotosPickerItem: PhotosPickerItem?
    var avatarImageToCrop: UIImage?
    var avatarConfirmedCroppedImage: UIImage?
    
    var showCroppingView: Binding<Bool>
    var presentingAlert: ProfileEditingAlert?
    
    private(set) var mediaTabVisibilitySetting: MediaTabVisibilitySetting = .showMediaTab
    private(set) var mediaTabRepliesSetting: MediaTabRepliesSetting = .showDirectPostsOnly
    private(set) var featuredTabVisibilitySetting: FeaturedTabVisibilitySetting = .showFeaturedTab
    
    var customFields: [Mastodon.Entity.Field]? = nil
    var emojis: [Mastodon.Entity.Emoji] = []
    
    var isAutomatedAccount: Bool = false
    
    private(set) var initialInfo: MastodonAccount? = nil
    
    init() {
        selectedBannerImage = Binding<[PhotosPickerItem]>(get: {[]}, set: {_ in})
        selectedAvatar = Binding<[PhotosPickerItem]>(get: {[]}, set: {_ in})
        showCroppingView = Binding<Bool>(get: {false}, set: {_ in})
        
        showCroppingView = Binding<Bool>(
            get: { return self.avatarImageToCrop != nil },
            set: { newValue in }
        )
        
        selectedBannerImage = Binding<[PhotosPickerItem]>(
            get: { [self.bannerImagePhotosPickerItem].compactMap { $0 } },
            set: { newValue in
                self.bannerImagePhotosPickerItem = newValue.first
                if let item = self.bannerImagePhotosPickerItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            self.confirmedBannerImage = image
                        } else {
                            print("Failed to load banner image")
                        }
                    }
                }
            }
        )
        
        selectedAvatar = Binding<[PhotosPickerItem]>(
            get: { [self.avatarPhotosPickerItem].compactMap { $0 } },
            set: { newValue in
                self.avatarPhotosPickerItem = newValue.first
                if let item = self.avatarPhotosPickerItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            self.avatarImageToCrop = image
                        } else {
                            print("Failed to load avatar image")
                        }
                    }
                }
            }
        )
        
        displayNameFieldEditingViewModel.contentDidChange = { withAnimation { self.editingStatusBinding?.wrappedValue = .editing(hasChanges: true) } }
        bioFieldEditingViewModel.contentDidChange = { withAnimation { self.editingStatusBinding?.wrappedValue = .editing(hasChanges: true) } }
    }
    
    func checkForChanges() {
        let hasChanges = confirmedBannerImage != nil ||
        avatarConfirmedCroppedImage != nil ||
        (initialInfo != nil && isAutomatedAccount != initialInfo?.metadata.isBot) ||
        customFields != initialInfo?.metadata.customFieldsForEdit
        if hasChanges {
            withAnimation { editingStatusBinding?.wrappedValue = .editing(hasChanges: true) }
        }
    }
    
    func setAccount(_ account: MastodonAccount) {
        initialInfo = account
        updateAccountTextFields(account: account)
        updateCustomFields(account: account)
        updateMetaData(account: account)
        if customFields?.first(where: { $0.verifiedAt != nil }) != nil {
            showVerifiedLinkTip = false
        }
        avatarConfirmedCroppedImage = nil
        avatarPhotosPickerItem = nil
        avatarImageToCrop = nil
        confirmedBannerImage = nil
        bannerImagePhotosPickerItem = nil
        presentingAlert = nil
        
        showTabDisplayPreferences = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.profileSettings) ?? false
    }
    
    func updateAccountTextFields(account: MastodonAccount) {
        let displayNameContent = account.displayInfo.displayName
        displayNameFieldEditingViewModel.stringContent = displayNameContent
        
        let bioContent = normalize(htmlString: account.bioForEdit)
        bioFieldEditingViewModel.stringContent = bioContent ?? ""
    }
    
    func updateCustomFields(account: MastodonAccount) {
        customFields = account.metadata.customFieldsForEdit
        emojis = account._legacyEntity.emojis
    }
    
    func updateMetaData(account: MastodonAccount) {
        mediaTabVisibilitySetting = account.metadata.showsMediaTab ? .showMediaTab : .hideMediaTab
        mediaTabRepliesSetting = account.metadata.mediaTabIncludesReplies ? .includeMyRepliesToOthers : .showDirectPostsOnly
        featuredTabVisibilitySetting = account.metadata.showsFeaturedTab ? .showFeaturedTab : .hideFeaturedTab
        isAutomatedAccount = account.metadata.isBot
    }
    
    func beginEditingField(_ fieldType: ORIGINALProfileEditingView.FieldEditType) {
        switch fieldType {
        case .create:
            fieldEditingState = .init(editingField: fieldType,
                                      labelEditingModel: MetaTextInputFieldViewModel(stringContent: "", placeholder: "", characterLimit: .softLimit(100), autocompleteMastodonItems: false),
                                      valueEditingModel: MetaTextInputFieldViewModel(stringContent: "", placeholder: "", characterLimit: .softLimit(220), autocompleteMastodonItems: true))
        case .edit(let field):
            fieldEditingState = .init(editingField: fieldType,
                                      labelEditingModel: MetaTextInputFieldViewModel(stringContent: field.name, placeholder: "", characterLimit: .softLimit(100), autocompleteMastodonItems: false),
                                      valueEditingModel: MetaTextInputFieldViewModel(stringContent: field.value, placeholder: "", characterLimit: .softLimit(220), autocompleteMastodonItems: true))
        }
    }
    
    func commitEditingField() {
        guard let fieldEditingState else { return }
        let labelText = fieldEditingState.labelEditingModel.stringContent
        let valueText = fieldEditingState.valueEditingModel.stringContent
        guard !labelText.isEmpty, !valueText.isEmpty else { return }
        
        let newField = Mastodon.Entity.Field(name: labelText, value: valueText)
        
        switch fieldEditingState.editingField {
        case .create:
            customFields?.append(newField)
        case .edit(let field):
            if let replaceIndex = customFields?.firstIndex(of: field) {
                customFields?[replaceIndex] = newField
            } else {
                customFields?.append(newField)
            }
        }
        self.fieldEditingState = nil
        
        checkForChanges()
    }
    
    func requestDeleteCustomField(_ field: Mastodon.Entity.Field) {
        presentingAlert = .deleteCustomField(field)
    }
    
    func confirmDeleteCustomField() {
        let deletingField: Mastodon.Entity.Field? = {
            switch presentingAlert {
            case .deleteCustomField(let field):
                return field
            case nil:
                return nil
            }
        }()
        guard let field = deletingField, let index = customFields?.firstIndex(of: field) else { return }
        customFields?.remove(at: index)
        presentingAlert = nil
        checkForChanges()
    }
    
    func cancelDeleteCustomField() {
        presentingAlert = nil
    }
}

extension ProfileEditingViewModel {
    func setMediaTabVisibilitySetting(_ newSetting: MediaTabVisibilitySetting) {
        guard newSetting != mediaTabVisibilitySetting else { return }
        mediaTabVisibilitySetting = newSetting
    }
    
    func setMediaTabRepliesSetting(_ newSetting: MediaTabRepliesSetting) {
        guard newSetting != mediaTabRepliesSetting else { return }
        mediaTabRepliesSetting = newSetting
    }
    
    func setFeaturedTabVisibilitySetting(_ newSetting: FeaturedTabVisibilitySetting) {
        guard newSetting != featuredTabVisibilitySetting else { return }
        featuredTabVisibilitySetting = newSetting
    }
}

extension ProfileEditingViewModel {
    enum ProfileEditingAlert {
        case deleteCustomField(Mastodon.Entity.Field)
        
        var title: String {
            switch self {
            case .deleteCustomField:
                "Delete custom field?"
            }
        }
        
        var messageText: String {
            switch self {
            case .deleteCustomField:
                "Are you sure you want to delete this custom field? This action can’t be undone."
            }
        }
    }
}

extension ProfileEditingViewModel {
    enum MediaTabVisibilitySetting: Int {
        case showMediaTab
        case hideMediaTab
    }
    
    enum MediaTabRepliesSetting: Int {
        case showDirectPostsOnly
        case includeMyRepliesToOthers
    }
    
    enum FeaturedTabVisibilitySetting: Int {
        case showFeaturedTab
        case hideFeaturedTab
    }
}

func normalize(htmlString: String?) -> String? {
    let _note = htmlString?.replacingOccurrences(of: "<br>|<br />", with: "\u{2028}", options: .regularExpression, range: nil)
        .replacingOccurrences(of: "</p>", with: "</p>\u{2029}", range: nil)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let note = _note, !note.isEmpty else {
        return nil
    }
    
    let html = try? HTML(html: note, encoding: .utf8)
    return html?.text
}

enum ProfileSection {
    case customFields
    case displayPreferences
    case advancedSettings
    
    var title: String? {
        switch self {
        case .customFields:
            return "Custom fields" // TODO: needs L10n
        case .displayPreferences:
            return "Display preferences"// TODO: needs L10n
        case .advancedSettings:
            return "Advanced settings"
        }
    }
    
    var tipText: String? {
        switch self {
        case .customFields:
            return "How to add a verified link"// TODO: needs L10n
        case .displayPreferences:
            return "Displays may vary across servers and apps."// TODO: needs L10n
        case .advancedSettings:
            return "Informs others that most posts from this account are..."
        }
    }
}

struct ProfileSectionHeader: View {
    let section: ProfileSection
    
    var body: some View {
        if let title = section.title {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
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

struct DisplayPreferencesEditor: View {
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
            
            Divider()
            
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
                // TODO: navigate
            }
        }
    }
}

struct AdvancedSettingsEditor: View {
    @Environment(ProfileEditingViewModel.self) var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading) {
            ProfileSectionHeader(section: .advancedSettings)
            Spacer()
            SubsectionHeading(title: "Automated account", subtitle: "Informs others that most posts from this account are automated and won’t be monitored") // TODO: L10n
            Toggle(isOn: $viewModel.isAutomatedAccount) {
                Text("Mark as an automated account") // TODO: L10n
            }
            .tint(Asset.Colors.accent.swiftUIColor)
        }
    }
}

@ViewBuilder func infoButton(_ section: ProfileSection) -> some View {
    if let text = section.tipText {
        Button() {
            // TODO: bring up tip
        } label: {
            HStack(spacing: tinySpacing) {
                Image(systemName: "questionmark.circle")
                Text(text)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .underline()
            }
            .foregroundColor(.secondary)
        }
    }
}

struct SubsectionHeading: View {
    let title: String?
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            if let title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RadioButtonArray: View {
    let items: [(Int, String)]
    @Binding var selectedItem: Int
    
    let selectionIndicatorSize: CGFloat = 16
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(items, id: \.self.1) { (index, item) in
                HStack {
                    selectionImage(selected: index == selectedItem)
                    Text(item)
                }
                .onTapGesture {
                    selectedItem = index % items.count
                }
            }
        }
    }
    
    @ViewBuilder func selectionImage(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? .clear : .secondary)
                .fill(selected ? Asset.Colors.accent.swiftUIColor : .clear)
                .frame(width: selectionIndicatorSize, height: selectionIndicatorSize)
            Circle()
                .blendMode(.destinationOut)
                .frame(width: selectionIndicatorSize - 8, height: selectionIndicatorSize - 8)
        }
        .compositingGroup()
    }
}

let brandBackgroundColor: Color = Asset.Colors.Brand.lightBlurple.swiftUIColor.opacity(0.2)

extension ProfileViewModel {
    func commitEdits() async throws {
        guard let authentication = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication else { throw APIService.APIError.explicit(.authenticationMissing) }
        
        let authenticationBox = MastodonAuthenticationBox(authentication: authentication)
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        func sizeLimitedImage(_ image: UIImage?, noLargerThan targetPixelSize: CGSize) -> UIImage? {
            guard let image else { return nil }
            if image.size.width <= targetPixelSize.width && image.size.height <= targetPixelSize.height {
                return image
            } else {
                let resized = image.af.imageScaled(to: targetPixelSize)
                return resized
            }
        }
        
        let updatedAvatarImage = sizeLimitedImage(editingViewModel.avatarConfirmedCroppedImage, noLargerThan: avatarImageMaxSizeInPixels)
        let updatedBannerImage = sizeLimitedImage(editingViewModel.confirmedBannerImage, noLargerThan: bannerImageMaxSizeInPixels)
        
        let customFieldsData = editingViewModel.customFields?.map { Mastodon.Entity.Field(name: $0.name, value: $0.value) }
        
        let query = Mastodon.API.Account.UpdateCredentialQuery(
            discoverable: nil,
            bot: editingViewModel.isAutomatedAccount,
            displayName: String(editingViewModel.displayNameFieldEditingViewModel.stringContent.prefix(30)),
            note: editingViewModel.bioFieldEditingViewModel.stringContent,
            avatar: updatedAvatarImage.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: updatedBannerImage.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            locked: nil,
            source: nil,
            fieldsAttributes: customFieldsData
        )
        let response = try await APIService.shared.accountUpdateCredentials(
            domain: domain,
            query: query,
            authorization: authorization
        )
        let updatedAccount = MastodonAccount.fromEntity(response.value, authenticatedDomain: domain)
        account = updatedAccount
        editingViewModel.setAccount(updatedAccount)
    }
    
    func commitTabSettingsChanges() async throws {
        guard let navigator, let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { throw APIService.APIError.explicit(.authenticationMissing) }
        
        let updatedProfile = try await APIService.shared.updateTabDisplaySettings(showFeaturedTab: editingViewModel.featuredTabVisibilitySetting == .showFeaturedTab, showMediaTab: editingViewModel.mediaTabVisibilitySetting == .showMediaTab, showMediaReplies: editingViewModel.mediaTabRepliesSetting == .includeMyRepliesToOthers, authenticationBox: authBox)
        guard let updatedAccount = account?.byUpdatingTabSettings(
            showFeaturedTab: updatedProfile.showFeatured,
            showMediaTab: updatedProfile.showMedia,
            showMediaReplies: updatedProfile.showMediaReplies
        ) else { return }
        
        set(account: updatedAccount, relationship: .isMe, navigator: navigator)
        editingViewModel.setAccount(updatedAccount)
    }
}

struct ProfileEditingDestinationView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    @State var hasChanges = false
    
    let destinationType: ProfileEditDestinationType
    
    var body: some View {
        rootContents
            .navigationTitle(profileViewModel.navigationTitle(destinationType))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                    } label: {
                        if hasChanges {
                            Image(systemName: "checkmark.circle.fill")
                        } else {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                }
            }
    }
    
    @ViewBuilder var rootContents: some View {
        Text(destinationType.id)
    }
    
   
}

extension ProfileViewModel {
    var bioIsEmpty: Bool {
        guard let bioForEdit = account?.bioForEdit else { return true }
        return bioForEdit.isEmpty
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


let avatarImageMaxSizeInPixels = CGSize(width: 400, height: 400)
let bannerImageMaxSizeInPixels = CGSize(width: 1500, height: 500)
