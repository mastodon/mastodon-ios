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
    
    init(wrapInSwiftUINavigationStack: Bool) {
        self.wrapInSwiftUINavigationStack = wrapInSwiftUINavigationStack
        let navigationRouter = MastodonNavigationRouter()
        self.navigationRouter = navigationRouter
        let root = ProfileView(wrapInSwiftUINavigationStack: wrapInSwiftUINavigationStack)
            .environment(viewModel)
            .environment(viewModel.relationshipViewModel)
            .environment(nestedScrollViewModel)
            .environment(navigationRouter)
        super.init(rootView: AnyView(root))
        title = nil
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !wrapInSwiftUINavigationStack {
            navigationRouter.navigationController = navigationController
        }
        super.viewDidAppear(animated)
    }
    
    func set(account: MastodonAccount, relationship: MastodonAccount.Relationship) {
        viewModel.account = account
        viewModel.editingViewModel.setAccount(account)
        viewModel.relationship = relationship
        viewModel.postsViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: .init(.userPosts)), asyncRefreshViewModel: AsyncRefreshViewModel())
        viewModel.mediaViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: .init(.mediaOnly)), asyncRefreshViewModel: AsyncRefreshViewModel())
        viewModel.relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: account.locked)
        
        for timelineModel in [viewModel.postsViewModel, viewModel.mediaViewModel] {
            timelineModel?.parentVcPresentScene = { (scene, transition) in
                self.sceneCoordinator?.present(scene: scene, from: self, transition: transition)
            }
        }
        
        viewModel.relationshipViewModel.actionHandler = viewModel.postsViewModel
        
        switch relationship {
        case .isMe:
            viewModel.editingStatus = .notEditing
        case .isNotMe:
            viewModel.editingStatus = .cannotEdit
        }
        
        Task {
            let handle = account.handle
            let handleComponents = handle.split(separator: "@").map { String($0) }
            if handleComponents.count > 1 {
                // server is included
                viewModel.handleDetails = .init(username: handleComponents.first ?? "", domain: handleComponents.last ?? "", isMyDomain: false)
            } else {
                // this account is on my server
                if let myDomain = AuthenticationServiceProvider.shared.currentActiveUser.value?.domain {
                    viewModel.handleDetails = .init(username: handleComponents.first ?? "", domain: myDomain, isMyDomain: true)
                }
            }
        }
    }
}

struct ProfileView: View {
    @Environment(MastodonNavigationRouter.self) private var navigationRouter
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
        @Bindable var navigationRouter = navigationRouter
        
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

                        HStack {
                            AccountStatsView(displayType: .smallInline(joinedOn: viewModel.account?.metadata.createdAt), accountMetrics: viewModel.account?.metrics) { stat in
                                switch stat {
                                case .postCount:
                                    break
                                case .followersCount:
                                    break
                                case .followingCount:
                                    break
                                }
                            }
                            .padding(.leading, doublePadding)
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                        .frame(width: min(maxFeedContentWidth, geo.size.width))
                        
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
                            
                            subview(.paginationControl, width: geo.size.width)
                                .id(Subview.paginationControl)
                                .frame(width: min(maxFeedContentWidth, geo.size.width))
                            Divider()
                            
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
            let familiarFollowersModel = TimelineListViewModel(timeline: .familiarFollowers(account.id), asyncRefreshViewModel: nil)
            viewModel.familiarFollowersViewModel = familiarFollowersModel
            try await familiarFollowersModel.doInitialLoad()
        }
    }
    
    @ViewBuilder func subview(_ subviewType: Subview, width: CGFloat) -> some View {
        switch subviewType {
        case .bannerAndAvatar:
            ProfileAvatarAndBannerView(width: width)
                .environment(viewModel.editingViewModel)
        case .mainInfo:
            if let familiarFollowersModel = viewModel.familiarFollowersViewModel {
                ProfileInfoView()
                    .environment(viewModel.familiarFollowersViewModel)
            }
        case .paginationControl:
            ProfilePaginationControl()
            .frame(width: min(width, maxFeedContentWidth))
        case .pages:
            ProfilePaginatingView()
        }
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
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            
            VStack(alignment: .leading, spacing: 0) {
                // DISPLAY NAME
                let displayName = viewModel.account?.displayInfo.displayName ?? "No Name"
                MastodonContentView.header(html: displayName, emojis: viewModel.account?.displayInfo.emojis ?? [], style: .profileDisplayName)
                
                // HANDLE
                let handle = viewModel.account?.displayInfo.fullHandle ?? "@unknown"
                HStack(alignment: .top, spacing: tinySpacing) {
                    Text(handle)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Image(systemName: "info.circle")
                        .foregroundColor(Asset.Colors.accent.swiftUIColor)
                        .font(.caption)
                }
                .onTapGesture {
                    isShowingHandleInfo = !isShowingHandleInfo
                }
                .popover(isPresented: $isShowingHandleInfo) {
                    ScrollView() {
                        HandleInfoPopover()
                    }
                }
                
                // SERVER ROLES
                if let domain = viewModel.account?.domain, let roles = viewModel.account?._legacyEntity.publicRoles, !roles.isEmpty {
                    Spacer()
                        .frame(height: tinySpacing)
                    FlowLayout(maxItemWidth: 300) {
                        ForEach(roles, id: \.id) { role in
                            ProfileBadge.role(role, domain: domain)
                        }
                    }
                }
                
                // FAMILIAR FOLLOWERS
                if let familiarFollowers = familiarFollowersViewModel.familiarFollowers {
                    FamiliarFollowersElement(familiarFollowers: familiarFollowers)
                        .onTapGesture {
                            if let account = viewModel.account {
                                navigationRouter.navigate(to: .familiarFollowers(account: account, listViewModel: familiarFollowersViewModel))
                            }
                        }
                }
                
            }
            
            HStack {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
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
                    .fill(Asset.Colors.Brand.backgroundSoftest.swiftUIColor)
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

struct CustomFieldsFlow: View {
    @Environment(\.displayScale) var displayScale
    var maxItemWidth: CGFloat
    var fields: [Mastodon.Entity.Field]
    var emojis: [Mastodon.Entity.Emoji]
    
    var body: some View {
        FlowLayout(maxItemWidth: maxItemWidth) {
            ForEach(fields, id: \.self) { field in
                card(field, emojis: emojis)
            }
        }
    }
    
    @ViewBuilder func card(_ field: Mastodon.Entity.Field, emojis: [Mastodon.Entity.Emoji]) -> some View {
        HStack(alignment: .bottom, spacing: tinySpacing) {
            VStack(alignment: .leading, spacing: tinySpacing) {
                MastodonContentView.customProfileField(html: field.name, emojis: emojis, bold: false)
                MastodonContentView.customProfileField(html: field.value, emojis: emojis, bold: true)
            }
            if field.verifiedAt != nil {
                Asset.Scene.Profile.About.verifiedLinkBadge.swiftUIImage
            }
        }
        .font(.footnote)
        .padding(standardPadding)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .stroke(.secondary, lineWidth: 1 / displayScale)
        }
    }
}

struct CustomFieldsStack: View {
    var fields: [Mastodon.Entity.Field]
    var emojis: [Mastodon.Entity.Emoji]
    
    private let labelWidth: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(fields, id: \.self) { field in
                customFieldRow(field, emojis: emojis)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, doublePadding)
                    .background {
                        if field.verifiedAt != nil {
                            Asset.Colors.Brand.backgroundSoftest.swiftUIColor
                        }
                    }
            }
        }
    }
    
    @ViewBuilder func customFieldRow(_ field: Mastodon.Entity.Field, emojis: [Mastodon.Entity.Emoji]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            MastodonContentView.customProfileField(html: field.name, emojis: emojis, bold: false)
                .foregroundColor(.secondary)
                .frame(width: labelWidth, alignment: .leading)
            
            Spacer()
                .frame(width: standardPadding)
            
            MastodonContentView.customProfileField(html: field.value, emojis: emojis, bold: true)
                .foregroundColor(Asset.Colors.accent.swiftUIColor)
            
            if field.verifiedAt != nil {
                Spacer()
                    .frame(width: tinySpacing)
                Asset.Scene.Profile.About.verifiedLinkBadge.swiftUIImage
            }
        }
        .font(.footnote)
        .lineLimit(1)
        .padding(.vertical, standardPadding)
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
            ForEach(ProfilePage.allCases, id: \.self) { page in
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
    @Environment(MastodonNavigationRouter.self) var navigationRouter
    
    var body: some View {
        HStack(spacing: standardPadding) {
            if let account = viewModel.account {
                relationshipViewModel.button.largeButton {
                    switch relationshipViewModel.button {
                    case .edit:
                        navigationRouter.navigate(to: .editProfile(profileViewModel: viewModel, editingViewModel: viewModel.editingViewModel))
                    default:
                        Task {
                                try await relationshipViewModel.doRelationshipAction(relationshipViewModel.button.buttonAction, account: account)
                        }
                    }
                }
                .glassEffectIfAvailable(.regular(interactive: true), in: .capsule)
                
                Button() {
                    
                } label: {
                    ZStack {
                        Circle()
                            .fill(.clear)
                            .frame(width: 48, height: 48)
                        Image(systemName: "at")
                    }
                }
                .glassEffectIfAvailable(.regular(interactive: true), in: .circle)
                
                Button() {
                    
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
}

struct ProfilePaginatingView: View {
    @Environment(ProfileViewModel.self) var viewModel
    
    var body: some View {
        GeometryReader() { geo in
                TabView(selection: Binding<ProfilePage>(
                    get: { viewModel.selectedPage },
                    set: { newValue in viewModel.selectedPage = newValue }
                )) {
                    ForEach(ProfilePage.allCases, id: \.self) { page in
                        switch page {
                        case .about:
                            ProfileAboutPage()
                                .nestedScrollview(.inner)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .environment(viewModel.relationshipViewModel)
                        case .activity:
                            TimelineListView()
                                .environment(viewModel.postsViewModel)
                                .environment(viewModel.postsViewModel?.timeline.filterModel)
                                .environment(AsyncRefreshViewModel())
                                .tag(page)
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .mediaOnly:
                            TimelineListView()
                                .environment(viewModel.mediaViewModel)
                                .environment(viewModel.mediaViewModel?.timeline.filterModel)
                                .environment(AsyncRefreshViewModel())
                                .tag(page)
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .featured:
                            Color.red
                                .tag(page)
                                .nestedScrollview(.inner)
                                .frame(width: geo.size.width, height: geo.size.height)
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
    case about
    case activity
    case mediaOnly
    case featured
    
    var title: String {
        switch self {
        case .about:
            L10nLookup.Scene.Profile.SegmentedControl.about
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
        case .about:
                .activity
        case .activity:
                .mediaOnly
        case .mediaOnly:
                .featured
        case .featured:
                .about
        }
    }
}

enum EditingStatus: Equatable {
    case cannotEdit
    case notEditing
    case editing(hasChanges: Bool)
    case pushingChanges(success: Bool?)
    
    var showSaveButton: Bool {
        switch self {
        case .cannotEdit, .notEditing, .pushingChanges:
            return false
        case .editing(let hasChanges):
            return hasChanges
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
    
    var editingStatus: EditingStatus = .cannotEdit
    
    struct HandleDetails {
        let username: String
        let domain: String
        let isMyDomain: Bool
    }
    var account: MastodonAccount?
    var relationship: MastodonAccount.Relationship?
    var familiarFollowersViewModel: TimelineListViewModel?
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
    var selectedPage: ProfilePage = .about
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
        case .isNotMe(let relationshipInfo):
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
        
        editingViewModel.editingStatusBinding = Binding<EditingStatus>(
            get: { self.editingStatus },
            set: { newValue in self.editingStatus = newValue }
        )
    }
    
    @ToolbarContentBuilder func toolbar(relationship: MastodonAccount.Relationship) -> some ToolbarContent {
        switch relationship {
        case .isMe:
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "number")
                }
                Button {
                } label: {
                    Image(systemName: "bookmark")
                }
                Button {
                } label: {
                    Image(systemName: "star")
                }
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(placement: .topBarTrailing)
            }
            
            ToolbarItem(id: "share", placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(placement: .topBarTrailing)
            }
            
            ToolbarItem(id: "settings", placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        case .isNotMe(let info):
            ToolbarItem(id: "reply", placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "arrow.turn.up.left")
                }
            }
            ToolbarItem(id: "menu", placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    public func resetEditingViewModel() {
        guard let account else { return }
        editingViewModel.setAccount(account)
    }
}

extension ProfileViewModel: FeedCoordinatorUpdatable {
    func incorporateUpdate(_ update: UpdatedElement) {
        switch update {
        case .relationship(let updatedRelationship):
            relationshipViewModel.prepareForDisplay(relationship: updatedRelationship, theirAccountIsLocked: account?.locked ?? false)
        default:
            break
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
    case pinned
}

extension ProfileBadge: View {
    
    var icon: Image {
        switch self {
        case .role:
            return Asset.Scene.Profile.About.roleBadge.swiftUIImage
        case .pinned:
            return Image(systemName: "pin")
        }
    }
    
    var text: String {
        switch self {
        case .role(let roleEntity, let domain):
            "\(roleEntity.name) (\(domain))"
        case .pinned:
            L10nLookup.Scene.Profile.Badge.pinned
        }
    }
    
    var body: some View {
        HStack(spacing: tinySpacing) {
            icon
            Text(text)
        }
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .padding(tinySpacing)
        .background() {
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .fill(.secondary.quinary)
        }
    }
}

struct ProfileAboutPage: View {
    @Environment(ProfileViewModel.self) var viewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            // BIO
            MastodonContentView.timelinePost(html: viewModel.account?._legacyEntity.note ?? "", emojis: viewModel.account?.displayInfo.emojis ?? [], isInlinePreview: false)
                .padding(.horizontal, doublePadding)
            
            // CUSTOM FIELDS
            if let fields = viewModel.account?.metadata.customFields, !fields.isEmpty {
                CustomFieldsStack(fields: fields, emojis: viewModel.account?._legacyEntity.emojis ?? [])
            }
        }
        .padding(.vertical)
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
