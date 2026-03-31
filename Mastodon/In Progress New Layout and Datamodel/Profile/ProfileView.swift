// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import SDWebImageSwiftUI
import SwiftUI
import PhotosUI
import MastodonCore
import MastodonSDK
import MastodonUI
import Combine

class ProfileHostingViewController: UIHostingController<AnyView> {
    let wrapInSwiftUINavigationStack: Bool
    let viewModel = ProfileViewModel()
    let nestedScrollViewModel = NestedScrollInteractionViewModel()
    let navigationRouter: MastodonNavigationRouter
    
    init(navigationRouter: MastodonNavigationRouter) {
        self.wrapInSwiftUINavigationStack = {
            switch navigationRouter.navigationType {
            case .uiKit:
                return false
            case .swiftUI:
                return true
            }
        }()
        self.navigationRouter = navigationRouter
        let root = ProfileView(wrapInSwiftUINavigationStack: wrapInSwiftUINavigationStack)
            .environment(viewModel)
            .environment(viewModel.relationshipViewModel)
            .environment(nestedScrollViewModel)
            .environment(navigationRouter)
        super.init(rootView: AnyView(root))
        title = nil
        navigationRouter.navigationType = .uiKit(self)
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ProfileView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(ProfileViewModel.self) var viewModel
    @Environment(NestedScrollInteractionViewModel.self) var nestedScrollViewModel
    let wrapInSwiftNavigationStack: Bool
    
    @State var isPresentingActivityFilter: Bool = false
    @State var embeddedActionBarHasCaughtUpToFloatingActionBar: Bool = false
    
    enum Subview: Hashable {
        case bannerAndAvatar
        case mainInfo
        case paginationControl
        case pages
    }
    
    init(wrapInSwiftUINavigationStack: Bool) {
        self.wrapInSwiftNavigationStack = wrapInSwiftUINavigationStack
    }
    
    var body: some View {
        @Bindable var navigationRouter = navigator
        
        if wrapInSwiftNavigationStack {
            NavigationStack(path: $navigationRouter.navigationPath){
                content
                    .navigationDestination(for: MastodonNavigationDestination.self) { destination in
                        navigationRouter.destinationView(destination)
                    }
                    .onChange(of: viewModel.editingStatus) { oldValue, newValue in
                        switch newValue {
                        case .cannotEdit, .editing, .notEditing:
                            break
                        case .pushingChanges(let success):
                            guard success == true else { break }
                            navigationRouter.navigationPath.removeLast()
                        }
                    }
                    .onChange(of: navigationRouter.navigationPath) { oldValue, newValue in
                        if newValue.isEmpty {
                            viewModel.editingStatus = .notEditing
                            viewModel.resetEditingViewModel()
                        }
                    }
            }
            
        } else {
            content
        }
    }
    
    @ViewBuilder var content: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ScrollView() {
                    VStack(alignment: .center, spacing: 0) {
                        subview(.bannerAndAvatar, width: geo.size.width)
                            .id(Subview.bannerAndAvatar)
                            .frame(width: geo.size.width)
                        Spacer()
                            .frame(height: doublePadding)
                        subview(.mainInfo, width: geo.size.width)
                            .id(Subview.mainInfo)
                            .padding(.horizontal, doublePadding)
                            .frame(width: min(maxFeedContentWidth, geo.size.width))
                        
                        Spacer()
                            .frame(height: doublePadding)

                            AccountStatsView(displayType: .smallInline(joinedOn: viewModel.account?.metadata.createdAt), accountMetrics: viewModel.account?.metrics) { stat in
                                guard let accountID = viewModel.account?.id else { return }
                                switch stat {
                                case .postCount, .joinedOn:
                                    break
                                case .followersCount:
                                    if let count = viewModel.account?.metrics.followersCount, count > 0 {
                                        navigator.push(.timeline(.followers(ofUserId: accountID)))
                                    }
                                case .followingCount:
                                    if let count = viewModel.account?.metrics.followingCount, count > 0 {
                                        navigator.push(.timeline(.accountsFollowed(byUserId: accountID)))
                                    }
                                }
                            }
                            .padding(.leading, doublePadding)
                        .frame(width: min(maxFeedContentWidth, geo.size.width), alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                            .frame(height: doublePadding)
                        
                        ProfileActionBar()
                            .padding(.horizontal, doublePadding)
                            .frame(width: min(maxFeedContentWidth, geo.size.width))
                            .background() {
                                GeometryReader { embeddedGeo in
                                    Color.clear
                                        .preference(key: VerticalPositionKey.self, value: ["embedded": embeddedGeo.frame(in: CoordinateSpace.named("scrollview")).minY])
                                }
                            }
                            .opacity(embeddedActionBarHasCaughtUpToFloatingActionBar ? 1.0 : 0.0)
                        
                        VStack(spacing: 0) {
                            
                            Spacer()
                                .frame(height: doublePadding)
                            
                            // PAGE SELECTOR
                            subview(.paginationControl, width: geo.size.width)
                                .id(Subview.paginationControl)
                                .frame(width: min(maxFeedContentWidth, geo.size.width))
                            Divider()
                            
                            // PAGES
                            subview(.pages, width: geo.size.width)
                                .id(Subview.pages)
                        }
                        .frame(height: max(0, geo.size.height - geo.safeAreaInsets.top /*this is always 0*/ - 45 /*because the safeAreaInsets lie*/))
                    }
                }
                .nestedScrollview(.outer)
                .frame(width: geo.size.width, height: geo.size.height)
                .coordinateSpace(name: "scrollview")
                
                VStack {
                    Spacer()
                    ProfileActionBar()
                        .padding(.horizontal, doublePadding)
                        .frame(width: min(maxFeedContentWidth, geo.size.width))
                        .background() {
                            GeometryReader { floatingGeo in
                                Color.clear
                                    .preference(key: VerticalPositionKey.self, value: ["floating": floatingGeo.frame(in: CoordinateSpace.named("scrollview")).minY])
                            }
                        }
                        .opacity(embeddedActionBarHasCaughtUpToFloatingActionBar ? 0.0 : 1.0)
                }
                .frame(width: min(maxFeedContentWidth, geo.size.width), height: max(0, geo.size.height - geo.safeAreaInsets.bottom - 90))
            }
        }
        .ignoresSafeArea()
        .overlay() {
            if let personalNoteEditingState = viewModel.relationshipViewModel.personalNoteEditingState, personalNoteEditingState.type != .pending {
                personalNoteEditingView(personalNoteEditingState)
            } else if let focusedField = viewModel.focusedCustomField {
                focusedCustomFieldOverlay(focusedField)
            }
        }
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .onPreferenceChange(VerticalPositionKey.self) { values in
            guard
                let embedded = values["embedded"],
                let floating = values["floating"]
            else { return }
            
            embeddedActionBarHasCaughtUpToFloatingActionBar = floating >= embedded
        }
        .task(id: viewModel.account?.id) {
            try? await fetchFamiliarFollowers()
        }
        .onChange(of: viewModel.account?.id) {
            Task {
                try await fetchFamiliarFollowers()
            }
        }
    }
    
    private func fetchFamiliarFollowers() async throws {
        if let account = viewModel.account {
            let familiarFollowersModel = TimelineListViewModel(timeline: .familiarFollowers(account.id), navigator: navigator, asyncRefreshViewModel: nil)
            viewModel.familiarFollowersViewModel = familiarFollowersModel
            try await familiarFollowersModel.doInitialLoad(navigator: navigator)
        }
    }
    
    @ViewBuilder func subview(_ subviewType: Subview, width: CGFloat) -> some View {
        switch subviewType {
        case .bannerAndAvatar:
            ProfileAvatarAndBannerView(width: width)
                .environment(viewModel.editingViewModel)
        case .mainInfo:
            if let familiarFollowersViewModel = viewModel.familiarFollowersViewModel {
                ProfileInfoView(width: width)
                    .environment(familiarFollowersViewModel)
            }
        case .paginationControl:
            ProfilePaginationControl()
            .frame(width: min(width, maxFeedContentWidth))
        case .pages:
            ProfilePaginatingView()
        }
    }
    
    @ViewBuilder func personalNoteEditingView(_ editState: ProfileView.PersonalNoteEditState) -> some View {
        GeometryReader { _ in
            ZStack {
                Color.dimmingBackground
                    .onTapGesture {
                        self.viewModel.relationshipViewModel.cancelPersonalNoteEdit()
                    }
                
                VStack(alignment: .leading, spacing: doublePadding) {
                    Text(editState.type.title)
                        .fontWeight(.semibold)
                    
                    Divider()
                    
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                        Text("Personal notes are only visible to you.") // TODO: L10n
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(standardPadding)
                    .background() {
                        RoundedRectangle(cornerRadius: CornerRadius.standard)
                            .fill(Asset.Colors.FigmaToken.bgSoftest.swiftUIColor)
                    }
                    
                    VStack(alignment: .leading, spacing: tinySpacing) {
                        SubsectionHeading(title: "Personal note", subtitle: nil)  // TODO: L10n
                        MetaTextInputField(allowScroll: true, drawBackground: true, returnKeyType: .done)
                            .environment(editState.valueEditingModel)
                            .frame(height: 72)
                    }
                    
                    HStack {
                        Spacer()
                            .frame(maxWidth: .infinity)
                        
                        Button() {
                            withAnimation {
                                self.viewModel.relationshipViewModel.cancelPersonalNoteEdit()
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
                                viewModel.relationshipViewModel.commitPersonalNoteEdit()
                            }
                        } label: {
                            Text("Save")  // TODO: L10n
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
    
    @ViewBuilder func focusedCustomFieldOverlay(_ field: Mastodon.Entity.Field) -> some View {
        GeometryReader { _ in
            ZStack {
                Color.dimmingBackground
                    .onTapGesture {
                        self.viewModel.focusedCustomField = nil
                    }
                
                CustomFieldCard(field: field, emojis: viewModel.account?.displayInfo.emojis ?? [], showFullContents: true)
                    .frame(maxWidth: maxFeedContentWidth)
                    .padding(.horizontal, doublePadding)
            }
        }
    }
}

extension ProfileView {
    enum PersonalNoteEditType {
        case add
        case edit
        case pending
        
        var title: String {
            switch self {
            case .add: "Add a personal note" // TODO: L10n
            case .edit: "Edit personal note" // TODO: L10n
            case .pending: "" // not actually used
            }
        }
        
    }
    
    struct PersonalNoteEditState {
        let type: PersonalNoteEditType
        let accountID: Mastodon.Entity.Account.ID
        let valueEditingModel: MetaTextInputFieldViewModel
    }
}

let bannerFullHeight: CGFloat = 194
struct ProfileAvatarAndBannerView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    var width: CGFloat
    
    var body: some View {
        VStack {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)) {
                VStack(spacing: 0) {
                    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                        bannerView(width: width)
                            .frame(height: bannerFullHeight)
                            .clipped()
                            .background(.secondary) // in case there is no image
                        
                        switch profileViewModel.editingStatus {
                        case .editing:
                            bannerEditButton
                                .padding(.horizontal, doublePadding)
                                .padding(.vertical, standardPadding)
                        case .cannotEdit, .notEditing, .pushingChanges:
                            EmptyView()
                        }
                    }
                    Spacer()
                        .frame(height: 16)
                }
        
                HStack() {
                    ZStack {
                        AvatarView(size: .extraLarge, avatarSource: editingViewModel.avatarConfirmedCroppedImage != nil ? .local(Image(uiImage: editingViewModel.avatarConfirmedCroppedImage!)) : .url(profileViewModel.account?.avatarURL), goToProfile: nil)
                            .padding(.horizontal, doublePadding)
                            .frame(alignment: .leading)
                        switch profileViewModel.editingStatus {
                        case .editing:
                            // if the user has already chosen a new image, let them see it unobscured, but tapping the avatar will still bring up the photo picker
                            avatarEditButton(showButton: editingViewModel.avatarConfirmedCroppedImage == nil)
                                .frame(maxWidth: AvatarSize.extraLarge, maxHeight: AvatarSize.extraLarge)
                        case .cannotEdit, .notEditing, .pushingChanges:
                            EmptyView()
                        }
                    }
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
                .frame(width: min(width, maxFeedContentWidth))
            }
        }
    }
    
    @ViewBuilder func bannerView(width: CGFloat) -> some View {
        if let replacementImage = editingViewModel.confirmedBannerImage {
            Image(uiImage: replacementImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width)
        } else if let bannerUrl = profileViewModel.account?.displayInfo.bannerImageUrl {
            WebImage(url: bannerUrl) { phase in
                switch phase {
                case .empty:
                    EmptyView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width)
                case .failure:
                    Color.secondary
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder var bannerEditButton: some View {
        PhotosPicker(selection: editingViewModel.selectedBannerImage, maxSelectionCount: 1, matching: .images) {
            Text("Edit cover image")
                .padding(.vertical, tinySpacing)
                .padding(.horizontal)
                .tintedBlurBackground()
                .clipShape(.capsule)
                .glassEffectIfAvailable(.clear(interactive: true), in: .capsule)
                .foregroundStyle(.white)
        }
    }
    
    @ViewBuilder func avatarEditButton(showButton: Bool) -> some View {
        PhotosPicker(selection: editingViewModel.selectedAvatar, maxSelectionCount: 1, matching: .images) {
            if showButton {
                Image(systemName: "camera")
                    .font(.headline)
                    .padding()
                    .tintedBlurBackground()
                    .clipShape(Circle())
                    .glassEffectIfAvailable(.clear(interactive: true), in: .circle)
                    .foregroundStyle(.white)
            } else {
                Color.clear
            }
        }
    }
}

struct ProfileInfoView: View {
    @Environment(MastodonNavigationRouter.self) var navigationRouter
    @Environment(ProfileViewModel.self) var viewModel
    @Environment(RelationshipViewModel.self) var relationshipViewModel
    @Environment(TimelineListViewModel.self) var familiarFollowersViewModel
    @State var isShowingHandleInfo = false
    
    let width: CGFloat
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            
            VStack(alignment: .leading, spacing: 0) {
                // DISPLAY NAME
                let displayName = viewModel.account?.displayInfo.displayName ?? "No Name"
                MastodonContentView.header(html: displayName, emojis: viewModel.account?.displayInfo.emojis ?? [], style: .profileDisplayName)
                
                // HANDLE
                let handle = viewModel.account?.displayInfo.fullHandle ?? "@unknown"
                HStack(alignment: .firstTextBaseline, spacing: tinySpacing) {
                    Text(handle)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    if viewModel.handleDetails?.username != nil {
                        Image(systemName: "info.circle")
                            .foregroundColor(Asset.Colors.accent.swiftUIColor)
                            .font(.caption)
                    }
                }
                .onTapGesture {
                    isShowingHandleInfo = !isShowingHandleInfo
                }
                .popover(isPresented: $isShowingHandleInfo) {
                    ScrollView() {
                        HandleInfoPopover()
                    }
                    .presentationDetents([.fraction(0.5), .medium, .large])
                }
                
                Spacer()
                    .frame(height: tinySpacing)
                
                // SERVER ROLES
                if let badges {
                    Spacer()
                        .frame(height: tinySpacing)
                    FlowLayout(minItemCountPerRow: 1) {
                        ForEach(badges, id: \.id) { badge in
                            badge
                        }
                    }
                }
                
                // FAMILIAR FOLLOWERS
                switch relationshipViewModel.relationship {
                case .isMe, .none:
                    EmptyView()
                case .isNotMe:
                    if let familiarFollowers = familiarFollowersViewModel.familiarFollowers {
                        Spacer()
                            .frame(height: tinySpacing)
                        
                        FamiliarFollowersElement(familiarFollowers: familiarFollowers)
                            .onTapGesture {
                                if let account = viewModel.account {
                                    navigationRouter.push(.timeline(.familiarFollowers(account, familiarFollowersViewModel)))
                                }
                            }
                    }
                }
                
                if let personalNote = viewModel.relationshipViewModel.relationship?.info?.myOwnComment, !personalNote.isEmpty {
                    
                    Spacer()
                        .frame(height: tinySpacing)
                    
                    PersonalNoteView(note: personalNote, isPending: viewModel.relationshipViewModel.personalNoteEditingState?.type == .pending)
                        .onTapGesture() {
                            if let accountID = viewModel.account?.id {
                                viewModel.relationshipViewModel.beginEditingPersonalNote(account: accountID)
                            }
                        }
                }
                
                Spacer()
                    .frame(height: tinySpacing)
                
                // BIO
                MastodonContentView.timelinePost(html: viewModel.account?._legacyEntity.note ?? "", emojis: viewModel.account?.displayInfo.emojis ?? [], isInlinePreview: false)
                
                Spacer()
                    .frame(height: tinySpacing)
                
                // CUSTOM FIELDS
                if let fields = viewModel.account?.metadata.customFieldsForDisplay, !fields.isEmpty {
                    CustomFieldsFlow(focusedField: $viewModel.focusedCustomField, maxItemWidth: min(width * 0.4, maxFeedContentWidth), fields: viewModel.account?.metadata.customFieldsForDisplay ?? [], emojis: viewModel.account?._legacyEntity.emojis ?? [])
                }
            }
            
            HStack {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    var badges: [ProfileBadge]? {
        var _badges = [ProfileBadge]()
        if viewModel.account?.metadata.isBot == true {
            _badges.append(ProfileBadge.isBot)
        }
        if viewModel.relationship?.info?.iAmBlockingThem == true || viewModel.relationship?.info?.iAmBlockingTheirDomain == true {
            _badges.append(ProfileBadge.isBlocked)
        }
        if viewModel.relationship?.info?.iAmMutingThem == true {
            _badges.append(ProfileBadge.isMuted)
        }
        if let domain = viewModel.account?.domain {
            for role in viewModel.account?._legacyEntity.publicRoles ?? [] {
                _badges.append(ProfileBadge.role(role, domain: domain))
            }
        }
        
        guard !_badges.isEmpty else { return nil }
        
        return _badges
    }
}

struct HandleInfoPopover: View {
    @Environment(ProfileViewModel.self) var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: doublePadding) {
            Spacer()
            
            HStack() {
                Text(L10nLookup.Scene.Profile.HandleExplainerView.title)
            }
            .font(.title3)
            .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: standardPadding) {
                explainerRow(.username(viewModel.handleDetails?.username))
                explainerRow(.server(viewModel.handleDetails?.domain, isMyServer: viewModel.handleDetails?.isMyDomain ?? false))
            }
            
            Text(L10nLookup.Scene.Profile.HandleExplainerView.federationExplainerText)
                .tint(Asset.Colors.accent.swiftUIColor)
        }
        .padding(doublePadding)
    }
    
    enum ExplainerRowType {
        case username(String?)
        case server(String?, isMyServer: Bool)
        
        var image: Image {
            switch self {
            case .username:
                Image(systemName: "at")
            case .server:
                Image(systemName: "globe")
            }
        }
        
        var htmlString: String {
            switch self {
            case .username(let username):
                let plainString = L10nLookup.Scene.Profile.HandleExplainerView.usernameDetailWithExample(username: "\(username ?? "UNKNOWN")")
                return plainString.htmlParagraph(boldingSubstring: username, workingAroundEmojiCodes: [])
            case .server(let serverName, _):
                    let plainString = L10nLookup.Scene.Profile.HandleExplainerView.serverDetailWithExample(serverName: serverName ?? "UNKNOWN")
                return plainString.htmlParagraph(boldingSubstring: serverName, workingAroundEmojiCodes: [])
            }
        }
    }
    
    @ViewBuilder func explainerRow(_ type: ExplainerRowType) -> some View {
        HStack(alignment: .top) {
            ZStack {
                Circle()
                    .fill(Asset.Colors.FigmaToken.bgSoftest.swiftUIColor)
                    .frame(width: 28, height: 28)
                type.image
                    .frame(width: 16, height: 16)
                    .foregroundColor(.primary)
            }
            VStack(alignment: .leading) {
                MastodonContentView.timelinePost(html: type.htmlString, emojis: [], isInlinePreview: false)
            }
        }
    }
}

extension Mastodon.Entity.Field {
    var url: URL? {
       try? value.asURL()
    }
}

struct PersonalNoteView: View {
    let note: String
    let isPending: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            VStack(alignment: .leading) {
                Text( "Personal note (visible only to you)")  // TODO: L10n
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack {
                    Text(note)
                        .font(.footnote)
                        .opacity(isPending ? 0.0 : 1.0)
                    
                    if isPending {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .padding(standardPadding)
         
            Image(systemName: "square.and.pencil")
                .foregroundColor(Asset.Colors.accent.swiftUIColor)
                .padding(standardPadding)
        }
        .background() {
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .fill(Asset.Colors.FigmaToken.bgSoftest.swiftUIColor)
        }
    }
}

struct CustomFieldsFlow: View {
    @Binding var focusedField: Mastodon.Entity.Field?
    
    var maxItemWidth: CGFloat
    var fields: [Mastodon.Entity.Field]
    var emojis: [Mastodon.Entity.Emoji]
    
    var body: some View {
        FlowLayout(minItemCountPerRow: 1) {
            ForEach(fields, id: \.self) { field in
                CustomFieldCard(field: field, emojis: emojis, showFullContents: false)
                    .onTapGesture {
                        focusedField = field
                    }
            }
        }
    }
}

struct CustomFieldCard: View {
    @Environment(\.displayScale) var displayScale
    let field: Mastodon.Entity.Field
    let emojis: [Mastodon.Entity.Emoji]
    let showFullContents: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: tinySpacing) {
            VStack(alignment: .leading, spacing: tinySpacing) {
                MastodonContentView.customProfileField(html: field.name, emojis: emojis, bold: false, lineLimit: showFullContents ? nil : 1)
                MastodonContentView.customProfileField(html: field.value, emojis: emojis, bold: true, lineLimit: showFullContents ? nil : 1)
            }
            if field.verifiedAt != nil {
                Asset.Scene.Profile.About.verifiedLinkBadge.swiftUIImage
            }
        }
        .font(.footnote)
        .padding(showFullContents ? doublePadding : standardPadding)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .fill(field.verifiedAt != nil || showFullContents ? Asset.Colors.FigmaToken.bgSoftest.swiftUIColor : .clear )
                .stroke(.secondary, lineWidth: 1 / displayScale)
        }
    }
}


struct ProfilePaginationControl: View {
    @Environment(ProfileViewModel.self) var viewModel
    @Namespace var animationNamespace
    
    var body: some View {
        VStack {
            // Custom
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 0) {
                    customPicker
                }
            } else {
                customPicker
            }
        }
    }
    
    @ViewBuilder var customPicker: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.pagesToShow, id: \.self) { page in
                Button() {
                    withAnimation {
                        viewModel.selectedPage = page
                    }
                } label: {
                    ZStack {
                        VStack {
                            Text(page.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(viewModel.selectedPage == page ? Asset.Colors.accent.swiftUIColor : .primary)
                                .padding(.horizontal)
                            if viewModel.selectedPage == page {
                                    Rectangle()
                                        .fill(Asset.Colors.accent.swiftUIColor)
                                        .frame(height: 4)
                                        .padding(.horizontal)
                                        .matchedGeometryEffect(id: "profile_pagination_page_selection", in: animationNamespace)
                            } else {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(height: 4)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                    }
                }
            }
        }
    }
}

struct ProfileActionBar: View {
    @Environment(ProfileViewModel.self) var viewModel
    @Environment(RelationshipViewModel.self) var relationshipViewModel
    @Environment(MastodonNavigationRouter.self) var navigator
    
    var body: some View {
        HStack(spacing: standardPadding) {
            if let account = viewModel.account {
                relationshipViewModel.button.largeButton {
                    switch relationshipViewModel.button {
                    case .edit:
                        navigator.push(.editProfile(profileViewModel: viewModel, editingViewModel: viewModel.editingViewModel))
                    default:
                        Task {
                            try await relationshipViewModel.doRelationshipAction(relationshipViewModel.button.buttonAction, account: account, navigator: navigator)
                        }
                    }
                }
                .glassEffectIfAvailable(.regular(interactive: true), in: .capsule)
                
                ActionBarMenuButton()
            }
        }
    }
    
    struct ActionBarMenuButton: View {
        @Environment(MastodonNavigationRouter.self) private var navigator
        @Environment(ProfileViewModel.self) private var viewModel
        @Environment(RelationshipViewModel.self) private var relationshipViewModel
        
        var body: some View {
            Menu {
                if let account = viewModel.account {
                    let submenus = relationshipViewModel.profileMenuActions(account: account, relationship: relationshipViewModel.relationship)
                    ForEach(submenus, id: \.self.id) { submenu in
                        ForEach(submenu.items, id: \.self) { menuAction in
                            switch menuAction {
                            case .miscellaneous(let miscAction):
                                viewModel.menuItem(miscAction)
                            case .navigationalAction(let navAction):
                                let domainName: String? = {
                                    switch relationshipViewModel.relationship {
                                    case .isMe, .none:
                                        return nil
                                    case .isNotMe:
                                        return viewModel.account?.domain == AuthenticationServiceProvider.shared.currentActiveUser.value?.domain ? nil : viewModel.account?.domain
                                    }
                                }()
                                navigator.menuItem(navAction, notMyDomainName: domainName)
                            case .postAction:
                                EmptyView()
                            case .relationshipAction(let relAction):
                                relationshipViewModel.menuItem(relAction, forAccount: account, navigator: navigator)
                            }
                        }
                        Divider()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.clear)
                        .frame(width: 48, height: 48)
                    Image(systemName: "ellipsis")
                }
            }
            .glassEffectIfAvailable(.regular(interactive: true), in: .circle)
        }
    }
}

struct ProfilePaginatingView: View {
    @Environment(ProfileViewModel.self) var viewModel
    
    var body: some View {
        GeometryReader() { geo in
                TabView(selection: Binding<ProfilePage>(
                    get: { viewModel.selectedPage },
                    set: { newValue in viewModel.selectedPage = newValue }
                )) {
                    ForEach(viewModel.pagesToShow, id: \.self) { page in
                        switch page {
                        case .activity:
                            if let postsTimelineViewModel = viewModel.postsViewModel {
                                TimelineListView()
                                    .environment(postsTimelineViewModel)
                                    .environment(postsTimelineViewModel.timeline.filterModel)
                                    .environment(AsyncRefreshViewModel())
                                    .tag(page)
                                    .frame(width: geo.size.width, height: geo.size.height)
                            }
                        case .mediaOnly:
                            if let mediaTimelineViewModel = viewModel.mediaViewModel {
                                TimelineListView()
                                    .environment(mediaTimelineViewModel)
                                    .environment(mediaTimelineViewModel.timeline.filterModel)
                                    .environment(viewModel.mediaViewAsyncRefresh)
                                    .tag(page)
                                    .frame(width: geo.size.width, height: geo.size.height)
                            }
                        case .featured:
                            if let featuredTimelineViewModel = viewModel.featuredItemsViewModel {
                                TimelineListView()
                                    .environment(featuredTimelineViewModel)
                                    .environment(featuredTimelineViewModel.timeline.filterModel)
                                    .environment(viewModel.featuredItemsAsyncRefresh)
                                    .tag(page)
                                    .frame(width: geo.size.width, height: geo.size.height)
                            }
                        }
                      
                    }
                }
                .tabViewStyle(.page)
        }
    }
}

struct TestAllRelationshipButtons: View {
    var body: some View {
        VStack {
            ForEach(allButtonTypes, id: \.self.description) { buttonType in
                HStack {
                    Text(buttonType.description)
                    buttonType.button {
                    }
                    buttonType.largeButton {
                    }
                }
            }
        }
    }
    
    let allButtonTypes: [RelationshipButtonType] = [
        .error(nil),
        .updating,
        .iAmBlockingThem(isDomainBlock: true),
        .iAmBlockingThem(isDomainBlock: false),
        .iAmMutingThem,
        .iDoNotFollowThem(theyFollowMe: true, theirAccountIsLocked: true),
        .iDoNotFollowThem(theyFollowMe: false, theirAccountIsLocked: true),
        .iDoNotFollowThem(theyFollowMe: true, theirAccountIsLocked: false),
        .iDoNotFollowThem(theyFollowMe: false, theirAccountIsLocked: false),
        .iFollowThem(theyFollowMe: true),
        .iFollowThem(theyFollowMe: false),
        .iHaveRequestedToFollowThem
        ]
}

enum ProfilePage: CaseIterable, Hashable {
    case activity
    case mediaOnly
    case featured
    
    var title: String {
        switch self {
        case .activity:
            L10nLookup.Scene.Profile.SegmentedControl.activity
        case .mediaOnly:
            L10nLookup.Scene.Profile.SegmentedControl.media
        case .featured:
            L10nLookup.Scene.Profile.SegmentedControl.featured
        }
    }
    
    var nextPage: ProfilePage {
        switch self {
        case .activity:
                .mediaOnly
        case .mediaOnly:
                .featured
        case .featured:
                .activity
        }
    }
}

enum EditingStatus: Equatable {
    case cannotEdit
    case notEditing
    case editing(hasChanges: Bool)
    case pushingChanges(success: Bool?)
    
    enum SaveButton {
        case noButton
        case saveInProgress
        case canSave
    }
    
    var saveButton: SaveButton {
        switch self {
        case .cannotEdit, .notEditing:
            return .noButton
        case .pushingChanges:
            return .saveInProgress
        case .editing(let hasChanges):
            if hasChanges {
                return .canSave
            } else {
                return .noButton
            }
        }
    }
    
    var showActivityIndicator: Bool {
        switch self {
        case .pushingChanges(let success):
            return success == nil
        default:
            return false
        }
    }
}

@MainActor
@Observable class ProfileViewModel {
    let relationshipViewModel = RelationshipViewModel()
    
    let editingViewModel = {
        ProfileEditingViewModel()
    }()
    
    var featuredHashtagsModel = FeaturedHashtagsModel()
    
    var editingStatus: EditingStatus = .cannotEdit
    
    struct HandleDetails {
        let username: String
        let domain: String
        let isMyDomain: Bool
    }
    var navigator: MastodonNavigationRouter?
    var account: MastodonAccount?
    var relationship: MastodonAccount.Relationship?
    var familiarFollowersViewModel: TimelineListViewModel?
    var pagesToShow: [ProfilePage] = []
    var postsViewModel: TimelineListViewModel? {
        didSet {
            Task {
                switch await postsViewModel?.timeline {
                case .userPosts(_, let queryFilter):
                    activityFilter = queryFilter
                default:
                    activityFilter = nil
                }
            }
        }
    }
    private var activityFilter: TimelineQueryFilter?
    
    var mediaViewModel: TimelineListViewModel?
    {
        didSet {
            Task {
                switch await mediaViewModel?.timeline {
                case .userPosts(_, let queryFilter):
                    mediaFilter = queryFilter
                default:
                    mediaFilter = nil
                }
            }
        }
    }
    private var mediaFilter: TimelineQueryFilter?
    var mediaViewAsyncRefresh: AsyncRefreshViewModel?
    
    var featuredItemsViewModel: TimelineListViewModel?
    var featuredItemsAsyncRefresh: AsyncRefreshViewModel?
    var selectedPage: ProfilePage = .activity
    var focusedCustomField: Mastodon.Entity.Field?
    var handleDetails: HandleDetails?
    
    var navigationButtons: [UIBarButtonItem] {
        guard let account, let relationship else { return [] }
        switch relationship {
        case .isMe:
            let settings = UIBarButtonItem(image: .init(systemName: "gearshape"), style: .plain, target: self, action: nil)
            let hashtags = UIBarButtonItem(image: .init(systemName: "number"), style: .plain, target: self, action: nil)
            let bookmarks = UIBarButtonItem(image: .init(systemName: "bookmark"), style: .plain, target: self, action: nil)
            let favourites = UIBarButtonItem(image: .init(systemName: "star"), style: .plain, target: self, action: nil)
            let share = UIBarButtonItem(image: .init(systemName: "square.and.arrow.up"), style: .plain, target: self, action: nil)
            return [hashtags, bookmarks, favourites, share, settings]
        case .isNotMe:
            let menu = UIBarButtonItem(image: .init(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
            let reply = UIBarButtonItem(image: .init(systemName: "arrow.turn.up.left"), style: .plain, target: self, action: nil)
            return [menu, reply]
        }
    }
    
    private var updateSubscription: AnyCancellable?
    init() {
        self.updateSubscription = FeedCoordinator.shared.$mostRecentUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self, let update else { return }
                self.incorporateUpdate(update)
            }
    }
    
    public func set(account: MastodonAccount, relationship: MastodonAccount.Relationship, navigator: MastodonNavigationRouter) {
        self.navigator = navigator
        self.account = account
        self.editingViewModel.setAccount(account)
        self.relationship = relationship
        self.postsViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: .init(.userPosts(featuredHashtagsModel))), navigator: navigator, asyncRefreshViewModel: AsyncRefreshViewModel())
        
        featuredHashtagsModel.fetchFeaturedTags(account: account)
        
        if account.metadata.showsMediaTab {
            if mediaViewModel == nil {
                mediaViewAsyncRefresh = AsyncRefreshViewModel()
                let mediaQueryFilter = TimelineQueryFilter(.mediaOnly)
                mediaQueryFilter.excludeReplies = !account.metadata.mediaTabIncludesReplies
                self.mediaViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: mediaQueryFilter), navigator: navigator, asyncRefreshViewModel: mediaViewAsyncRefresh!)
            } else {
                self.updateMediaFilter()
            }
        } else {
            self.mediaViewModel = nil
        }
        
        if account.metadata.showsFeaturedTab {
            if self.featuredItemsViewModel == nil {
                featuredItemsAsyncRefresh = AsyncRefreshViewModel()
                self.featuredItemsViewModel = TimelineListViewModel(timeline: .featuredItems(userID: account.id), navigator: navigator, asyncRefreshViewModel: featuredItemsAsyncRefresh!)
            }
        } else {
            self.featuredItemsViewModel = nil
        }
        
        self.relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: account.locked)
        
        self.relationshipViewModel.actionHandler = self.postsViewModel
        
        switch relationship {
        case .isMe:
            self.editingStatus = .notEditing
        case .isNotMe:
            self.editingStatus = .cannotEdit
        }
        
        pagesToShow = pagesToShow(forAccount: account)
        
        Task {
            let handle = account.handle
            let handleComponents = handle.split(separator: "@").map { String($0) }
            if handleComponents.count > 1 {
                // server is included
                self.handleDetails = .init(username: handleComponents.first ?? "", domain: handleComponents.last ?? "", isMyDomain: false)
            } else {
                // this account is on my server
                if let myDomain = AuthenticationServiceProvider.shared.currentActiveUser.value?.domain {
                    self.handleDetails = .init(username: handleComponents.first ?? "", domain: myDomain, isMyDomain: true)
                }
            }
        }
    }
    
    public func resetEditingViewModel() {
        guard let account else { return }
        editingViewModel.setAccount(account)
    }
    
    public func updateMediaFilter() {
        guard let mediaFilter, let account else { return }
        let accountIsExcludingRepliesInMediaTab = !account.metadata.mediaTabIncludesReplies
        guard mediaFilter.excludeReplies != accountIsExcludingRepliesInMediaTab else { return }
        mediaFilter.excludeReplies = accountIsExcludingRepliesInMediaTab
        Task {
            await mediaViewModel?.forceReload(.mediaFilterUpdated)
        }
    }
}

extension ProfileViewModel: FeedCoordinatorUpdatable {
    func incorporateUpdate(_ update: UpdatedElement) {
        switch update {
        case .relationship(let updatedRelationship):
            relationshipViewModel.prepareForDisplay(relationship: updatedRelationship, theirAccountIsLocked: account?.locked ?? false)
        case .deletedPost, .hashtag, .post:
            break
        case .domainBlockChange(let domain, let isBlocked):
            if domain == account?.domain {
                relationshipViewModel.updateForDomainBlockChange(isBlocked: isBlocked)
            }
        }
    }
}

struct VerticalPositionKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    
    static func reduce(value: inout [String: CGFloat],
                       nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

enum ProfileBadge {
    case role(Mastodon.Entity.Account.AccountRole, domain: String)
    case isBlocked
    case isMuted
    case isBot
    case pinned
}

extension ProfileBadge: Identifiable {
    var id: String {
        switch self {
        case .role(let role, let domain):
            return "role-\(role.id)-\(domain)"
        case .isBlocked:
            return "blocked"
        case .isMuted:
            return "muted"
        case .isBot:
            return "bot"
        case .pinned:
            return "pinned"
        }
    }
}

extension ProfileBadge: View {
    
    var icon: Image {
        switch self {
        case .role:
            return Asset.Scene.Profile.About.roleBadge.swiftUIImage
        case .isBot:
            return Asset.Scene.Profile.About.botBadge.swiftUIImage
        case .isBlocked:
            return Image(systemName: "circle.slash")
        case .isMuted:
            return Image(systemName: "speaker.slash")
        case .pinned:
            return Image(systemName: "pin")
        }
    }
    
    var text: String {
        switch self {
        case .role(let roleEntity, let domain):
            "\(roleEntity.name) (\(domain))"
        case .isBot:
            "Automated account" // TODO: L10n
        case .isMuted:
            L10n.Common.Controls.Friendship.muted
        case .isBlocked:
            L10n.Common.Controls.Friendship.blocked
        case .pinned:
            L10nLookup.Scene.Profile.Badge.pinned
        }
    }
    
    var fillColor: Color {
        switch self {
        case .role, .pinned, .isBot:
            return Asset.Colors.FigmaToken.bgSoftest.swiftUIColor
        case .isMuted:
            return Asset.Colors.FigmaToken.bgInverted.swiftUIColor
        case .isBlocked:
            return Asset.Colors.FigmaToken.bgDangerBase.swiftUIColor
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .role, .pinned, .isBot:
            return Asset.Colors.FigmaToken.textSecondary.swiftUIColor
        case .isMuted:
            return Asset.Colors.FigmaToken.textInverted.swiftUIColor
        case .isBlocked:
            return Asset.Colors.FigmaToken.textInverted.swiftUIColor
        }
    }
    
    var body: some View {
        HStack(spacing: tinySpacing) {
            icon
            Text(text)
        }
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundColor(foregroundColor)
        .padding(tinySpacing)
        .background() {
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .fill(fillColor)
        }
    }
}

struct FamiliarFollowersElement: View {
    let familiarFollowers: TimelineListViewModel.FamiliarAccountsSummary
    let boldedNames: [(String, emojiCodes: [String])]
    let maxAvatarCount: Int = 3
    
    init(familiarFollowers: TimelineListViewModel.FamiliarAccountsSummary) {
        self.familiarFollowers = familiarFollowers
        self.boldedNames = familiarFollowers.firstFew.prefix(2).map {
            ($0.displayInfo.displayName, emojiCodes: $0.displayInfo.emojis.map { $0.shortcode })
        }
    }
    
    var body: some View {
        HStack {
        HStack(spacing: -8) {
            ForEach(familiarFollowers.firstFew.prefix(maxAvatarCount), id: \.id) { follower in
                AvatarView(size: .small, borderStyle: .both, avatarSource: .url(follower.avatarURL), goToProfile: nil)
            }
        }
            MastodonContentView.timelinePost(html: htmlDisplayString, emojis: familiarFollowers.firstFew.prefix(2).flatMap{ $0.displayInfo.emojis }, isInlinePreview: true)
        }
    }
    
    var htmlDisplayString: String {
        let plainString = {
            switch (boldedNames.count, familiarFollowers.totalCount) {
            case (1, 1):
                L10nLookup.Scene.FamiliarFollowers.followedByOneName(boldedNames[0].0)
            case (2, 2):
                L10nLookup.Scene.FamiliarFollowers.followedByTwoNames(firstAccount: boldedNames[0].0, secondAccount: boldedNames[1].0)
            default:
                L10nLookup.Scene.FamiliarFollowers.followedByTwoNamesAndOthers(firstAccount: boldedNames[0].0, secondAccount: boldedNames[1].0, otherCount: familiarFollowers.totalCount - 2)
            }
        }()
        
        let withBoldedNames = plainString.htmlParagraph(boldingSubstrings: boldedNames)
        return withBoldedNames
    }
}

extension TimelineListViewModel: @MainActor Equatable {
    static func == (lhs: TimelineListViewModel, rhs: TimelineListViewModel) -> Bool {
        lhs.timeline == rhs.timeline
    }
}

extension ProfileViewModel: MastodonMenuAction.MiscellaneousMenuActionHandler {
    func handleAction(_ action: MastodonMenuAction.MiscellaneousMenuAction) {
        switch action {
        case .copyLink:
            // link to this profile
            if let url = account?.metadata.profileUrl?.absoluteString {
                UIPasteboard.general.string = url
            }
        }
    }
}

extension ProfileViewModel {
    @ViewBuilder func menuItem(_ action: MastodonMenuAction.MiscellaneousMenuAction) -> some View {
        MastodonMenuAction.menuButton(systemImageName: action.iconSystemName, text: action.labelText) {
            self.handleAction(action)
        }
    }
}

extension ProfileViewModel {
    private func pagesToShow(forAccount account: MastodonAccount?) -> [ProfilePage] {
        var pages = [ProfilePage.activity]
        if account?.metadata.showsMediaTab == true {
            pages.append(.mediaOnly)
        }
        let canShowFeaturedTab = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.featuredAccounts) ?? false
        if canShowFeaturedTab && account?.metadata.showsFeaturedTab == true {
            pages.append(.featured)
        }
        return pages
    }
}

@MainActor
@Observable class FeaturedHashtagsModel {
    private(set) var featuredHashtags: [Mastodon.Entity.FeaturedTag] = []
    private(set) var isFetching: Bool = false
    
    private var fetchQueue: [Mastodon.Entity.Account.ID] = []
    
    func fetchFeaturedTags(account: MastodonAccount) {
        if !fetchQueue.contains(account.id) {
            fetchQueue.append(account.id)
        }

        guard !isFetching else { return }
        let nextToFetch = fetchQueue.removeFirst()
        isFetching = true
        Task {
            do {
                featuredHashtags = try await _fetchFeaturedTags(account: nextToFetch)
            } catch {
                // TODO: handle error?
            }
            isFetching = false
        }
    }
    
    private func _fetchFeaturedTags(account: Mastodon.Entity.Account.ID) async throws -> [Mastodon.Entity.FeaturedTag] {
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { throw APIService.APIError.explicit(.authenticationMissing) }
        return try await APIService.shared.featuredTags(forAccount: account, authenticationBox: authBox).value
    }
}
