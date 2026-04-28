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
    case displayName(profileViewModel: ProfileViewModel)
    case bio(profileViewModel: ProfileViewModel)
    
    case customFields(profileViewModel: ProfileViewModel)
    case editCustomField(profileViewModel: ProfileViewModel)
    case verifiedLinkInstructions(profileViewModel: ProfileViewModel)
    case reorderCustomFields(profileViewModel: ProfileViewModel)
    
    case featuredHashtags(profileViewModel: ProfileViewModel)
    case addHashtag(profileViewModel: ProfileViewModel)
    
    case profileTabSettings(profileViewModel: ProfileViewModel)
    
    
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
            "profile_tab_settings"
        case .verifiedLinkInstructions:
            "verified_link_instructions"
        case .editCustomField:
            "edit_custom_field"
        case .reorderCustomFields:
            "reorder_custom_fields"
        case .addHashtag:
            "add_hashtag"
        }
    }
    
    var editingViewModel: ProfileEditingViewModel {
        switch self {
        case .displayName(let profileViewModel), .bio(let profileViewModel):
            return profileViewModel.editingViewModel
        case .customFields(let profileViewModel), .featuredHashtags(let profileViewModel), .profileTabSettings(let profileViewModel):
            return profileViewModel.editingViewModel
        case .verifiedLinkInstructions(let profileViewModel):
            return profileViewModel.editingViewModel
        case .editCustomField(let profileViewModel):
            return profileViewModel.editingViewModel
        case .reorderCustomFields(let profileViewModel):
            return profileViewModel.editingViewModel
        case .addHashtag(let profileViewModel):
            return profileViewModel.editingViewModel
        }
    }
    
    var profileViewModel: ProfileViewModel {
        switch self {
        case .displayName(let profileViewModel), .bio(let profileViewModel):
            return profileViewModel
        case .customFields(let profileViewModel), .featuredHashtags(let profileViewModel), .profileTabSettings(let profileViewModel):
            return profileViewModel
        case .verifiedLinkInstructions(let profileViewModel):
            return profileViewModel
        case .editCustomField(let profileViewModel):
            return profileViewModel
        case .reorderCustomFields(let profileViewModel):
            return profileViewModel
        case .addHashtag(let profileViewModel):
            return profileViewModel
        }
    }
}

extension ProfileEditDestinationType {
    var expectsModalPresentation: Bool {
        switch self {
        case .displayName, .bio, .verifiedLinkInstructions, .editCustomField, .reorderCustomFields, .addHashtag:
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
            VStack(spacing: 0) {
                ProfileAvatarAndBannerView(maxWidth: geo.size.width)
                    .zIndex(2)
                List {
                    ForEach(allEditRows, id: \.id) { destination in
                        profileEditRow(destination)
                            .onTapGesture {
                                navigate(to: destination)
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $navigationRouter.isPresentingProfileEditSheet) {
                switch navigationRouter.presentedSheet {
                case .profileEditingSheet(let type):
                    ProfileEditingDestinationView(destinationType: type)
                        .environment(type.profileViewModel)
                        .environment(type.profileViewModel.editingViewModel)
                        .environment(navigationRouter)
                case .timelineSheet, .none:
                    EmptyView()
                }
            }
        }
    }
    
    var allEditRows: [ProfileEditDestinationType] {
        var rows: [ProfileEditDestinationType] = [
            .displayName(profileViewModel: profileViewModel),
            .bio(profileViewModel: profileViewModel),
            .customFields(profileViewModel: profileViewModel),
            .featuredHashtags(profileViewModel: profileViewModel)
        ]
        if editingViewModel.showTabDisplayPreferences {
            rows.append(.profileTabSettings(profileViewModel: profileViewModel))
        }
        return rows
    }
    
    func navigate(to editDestination: ProfileEditDestinationType) {
        if editDestination.expectsModalPresentation {
            navigator.presentModal(.editProfileNavigation(destination: editDestination))
        } else {
            navigator.push(.editProfileNavigation(destination: editDestination))
        }
    }
    
    func profileEditRow(_ destination: ProfileEditDestinationType) -> some View {
        HStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(mainLabelForRow(destination) ?? "")
                        .lineLimit(1)
                        .layoutPriority(3)
                        .foregroundColor(mainLabelColorForRow(destination))
                    if let subtitle = subtitleForRow(destination) {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .layoutPriority(2)
                    }
                }
                .layoutPriority(1)
                contentForRow(destination)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            disclosureIndicator(destination)
        }
        .contentShape(Rectangle())
    }
    
    func mainLabelColorForRow(_ destination: ProfileEditDestinationType) -> Color {
        switch destination {
        case .bio:
            profileViewModel.bioIsEmpty ? Asset.Colors.accent.swiftUIColor : .primary
        default:
            .primary
        }
    }
    
    func mainLabelForRow(_ destination: ProfileEditDestinationType) -> String? {
        switch destination {
        case .displayName:
            return L10nLookup.Scene.EditProfile.NavigationTitle.displayName
        case .bio:
            if profileViewModel.bioIsEmpty {
                return L10nLookup.Scene.EditProfile.NavigationTitle.addBio
            } else {
                return L10nLookup.Scene.EditProfile.NavigationTitle.bio
            }
        case .customFields:
            return L10nLookup.Scene.EditProfile.NavigationTitle.customFields
        case .featuredHashtags:
            return L10nLookup.Scene.EditProfile.NavigationTitle.featuredHashtags
        case .profileTabSettings:
            return L10nLookup.Scene.EditProfile.NavigationTitle.profileTabSettings
        case .verifiedLinkInstructions:
            return nil
        case .editCustomField, .reorderCustomFields, .addHashtag:
            return nil
        }
    }
    
    func subtitleForRow(_ destination: ProfileEditDestinationType) -> String? {
        switch destination {
        case .displayName, .bio, .profileTabSettings, .verifiedLinkInstructions, .editCustomField, .reorderCustomFields, .addHashtag:
            return nil
        case .customFields:
            return L10nLookup.Scene.EditProfile.NavigationTitle.customFieldsSubtitle
        case .featuredHashtags:
            return L10nLookup.Scene.EditProfile.NavigationTitle.featuredHashtagsSubtitle
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
                MastodonContentView.profileEditingRow(html: displayName, emojis: profileViewModel.account?.displayInfo.emojis ?? [], isLabel: false)
            } else {
                Spacer()
            }
        case .bio:
            if profileViewModel.bioIsEmpty {
                Spacer()
            } else if let bio = profileViewModel.account?.bioForDisplay {
                MastodonContentView.profileEditingRow(html: bio, emojis: profileViewModel.account?.displayInfo.emojis ?? [], isLabel: false)
            }
        case .customFields:
            Text("\(profileViewModel.account?.metadata.customFieldsForEdit?.count ?? 0)")
                .foregroundStyle(.secondary)
        case .featuredHashtags:
            switch profileViewModel.featuredHashtagsModel.currentFetchState {
            case .fetchingAll:
                ProgressView().progressViewStyle(.circular)
            default:
                Text("\(profileViewModel.featuredHashtagsModel.featuredHashtags.count)")
                    .foregroundStyle(.secondary)
            }
        case .profileTabSettings, .verifiedLinkInstructions, .editCustomField, .reorderCustomFields, .addHashtag:
            Spacer()
        }
    }
}

extension ProfileEditingViewModel {
    enum ProfileEditingAlert {
        case deleteCustomField(Mastodon.Entity.Field)
        
        var title: String {
            switch self {
            case .deleteCustomField:
                L10nLookup.Scene.EditProfile.CustomFields.deleteCustomFieldConfirmationAlertTitle
            }
        }
        
        var messageText: String {
            switch self {
            case .deleteCustomField:
                L10nLookup.Scene.EditProfile.CustomFields.deleteCustomFieldConfirmationAlertMessage
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

extension ProfileViewModel {
    var bioIsEmpty: Bool {
        guard let bioForEdit = account?.bioForEdit else { return true }
        return bioForEdit.isEmpty
    }
}

let brandBackgroundColor: Color = Asset.Colors.Brand.lightBlurple.swiftUIColor.opacity(0.2)
let avatarImageMaxSizeInPixels = CGSize(width: 400, height: 400)
let bannerImageMaxSizeInPixels = CGSize(width: 1500, height: 500)
