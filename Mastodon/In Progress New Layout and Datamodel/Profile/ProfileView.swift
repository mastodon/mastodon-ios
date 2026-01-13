// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import SDWebImageSwiftUI
import SwiftUI
import MastodonCore
import MastodonSDK
import Combine

class ProfileHostingViewController: UIHostingController<AnyView> {
    let viewModel = ProfileViewModel()
    let nestedScrollViewModel = NestedScrollInteractionViewModel()
    
    init(wrapInNavigationController: Bool) {
        let root = ProfileView(wrapInNavigationController: wrapInNavigationController).environment(viewModel).environment(viewModel.relationshipViewModel).environment(nestedScrollViewModel)
        super.init(rootView: AnyView(root))
        title = nil
    }
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func set(account: MastodonAccount, relationship: MastodonAccount.Relationship) {
        viewModel.account = account
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
    @Environment(ProfileViewModel.self) var viewModel
    @Environment(NestedScrollInteractionViewModel.self) var nestedScrollViewModel
    let wrapInNavigationController: Bool
    
    @State var isPresentingActivityFilter: Bool = false
    @State var embeddedActionBarHasCaughtUpToFloatingActionBar: Bool = false
    
    enum Subview: Hashable {
        case bannerAndAvatar
        case bio
        case customFieldsFlow
        case paginationControl
        case pages
    }
    
    var body: some View {
        if wrapInNavigationController {
            NavigationStack() {
                content
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
                        subview(.bio, width: geo.size.width)
                            .id(Subview.bio)
                            .padding(.horizontal, doublePadding)
                            .frame(width: min(maxFeedContentWidth, geo.size.width))
                        
                        Spacer()
                            .frame(height: doublePadding)
                        
                        if let fields = viewModel.account?.metadata.customFields, !fields.isEmpty {
                            subview(.customFieldsFlow, width: min(maxFeedContentWidth, geo.size.width) - doublePadding * 2)
                                .padding(.horizontal, doublePadding)
                                .frame(width: min(maxFeedContentWidth, geo.size.width))
                            
                            Spacer()
                                .frame(height: doublePadding)
                        }
                        
                        
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
                                        .preference(key: VerticalPositionKey.self, value: ["embedded": embeddedGeo.frame(in: .global).minY])
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
                
                VStack {
                    Spacer()
                    ProfileActionBar()
                        .padding(.horizontal, doublePadding)
                        .frame(width: min(maxFeedContentWidth, geo.size.width))
                        .background() {
                            GeometryReader { floatingGeo in
                                Color.clear
                                    .preference(key: VerticalPositionKey.self, value: ["floating": floatingGeo.frame(in: .global).minY])
                            }
                        }
                        .opacity(embeddedActionBarHasCaughtUpToFloatingActionBar ? 0.0 : 1.0)
                }
                .frame(width: min(maxFeedContentWidth, geo.size.width), height: geo.size.height - geo.safeAreaInsets.bottom - 90)
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
    }
    
    @ViewBuilder func subview(_ subviewType: Subview, width: CGFloat) -> some View {
        switch subviewType {
        case .bannerAndAvatar:
            ProfileAvatarAndBannerView(width: width)
        case .bio:
            ProfileInfoView()
        case .customFieldsFlow:
            CustomFieldsFlow(maxItemWidth: min(width, maxFeedContentWidth), fields: viewModel.account?.metadata.customFields ?? [], emojis: viewModel.account?._legacyEntity.emojis ?? [])
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
    @Environment(ProfileViewModel.self) var viewModel
    var width: CGFloat
    
    var body: some View {
        VStack {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)) {
                VStack(spacing: 0) {
                    bannerView(width: width)
                        .frame(height: bannerFullHeight)
                        .clipped()
                    Spacer()
                        .frame(height: 16)
                }
                HStack() {
                    AvatarView(size: .extraLarge, authorAvatarUrl: viewModel.account?.avatarURL, goToProfile: nil)
                        .padding(.horizontal, doublePadding)
                        .frame(alignment: .leading)
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
                .frame(width: min(width, maxFeedContentWidth))
            }
        }
    }
    
    @ViewBuilder func bannerView(width: CGFloat) -> some View {
        if let bannerUrl = viewModel.account?.displayInfo.bannerImageUrl {
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
}

struct ProfileInfoView: View {
    @Environment(ProfileViewModel.self) var viewModel
    @Environment(RelationshipViewModel.self) var relationshipViewModel
    @State var isShowingHandleInfo = false
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            
            VStack(alignment: .leading) {
                let handle = viewModel.account?.displayInfo.minimalHandle ?? "@unknown"
                
                HStack {
                    MastodonContentView.header(html: viewModel.account?.displayInfo.displayName ?? "No Name", emojis: viewModel.account?.displayInfo.emojis ?? [], style: .profileDisplayName)
                    #if false
                    if let roles = viewModel.account?._legacyEntity.publicRoles {
                        if roles.first(where: { $0.name.contains("admin") || $0.name.contains("Admin") }) != nil {
                            ProfileBadge.admin
                        }
                        if roles.first(where: { $0.name.contains("mod") || $0.name.contains("Mod") }) != nil {
                            ProfileBadge.moderator
                        }
                    }
                    #endif
                }

                HStack(alignment: .top, spacing: tinySpacing) {
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
                }
                MastodonContentView.timelinePost(html: viewModel.account?._legacyEntity.note ?? "", emojis: viewModel.account?.displayInfo.emojis ?? [], isInlinePreview: false)
            }
            
            HStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                if let relationship = viewModel.relationship {
                    switch relationship {
                    case .isMe:
                        if #available(iOS 26.0, *) {
                            Button {
                                
                            } label: {
                                Text("Edit Info")
                            }
                            .tint(Asset.Colors.accent.swiftUIColor)
                            .buttonStyle(.glassProminent)
                        } else {
                            Button {
                                
                            } label: {
                                Text("Edit Info")
                            }
                            .tint(Asset.Colors.accent.swiftUIColor)
                        }
                    case .isNotMe:
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct HandleInfoPopover: View {
    @Environment(ProfileViewModel.self) var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: doublePadding) {
            HStack() {
                Image(systemName: "person.crop.square.filled.and.at.rectangle")
                    .foregroundColor(.white)
                    .padding()
                    .background() {
                        Circle()
                            .fill(Asset.Colors.accent.swiftUIColor)
                    }
                Text(L10nLookup.Scene.Profile.HandleExplainerView.title)
            }
            .font(.title)
            
            if let handleDetails = viewModel.handleDetails {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L10nLookup.Scene.Profile.HandleExplainerView.exampleTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                        .frame(height: standardPadding)
                    
                    HStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack(alignment: .bottom) {
                                Image(systemName: "arrow.turn.left.down")
                                    .font(.caption2)
                                Text(L10nLookup.Scene.Profile.HandleExplainerView.exampleUsernameLabel)
                                    .font(.callout)
                            }
                            HStack(alignment: .top) {
                                Text("@\(handleDetails.username)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                VStack {
                                    Text("@\(handleDetails.domain)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    HStack(alignment: .top) {
                                        Text(L10nLookup.Scene.Profile.HandleExplainerView.exampleServerLabel)
                                            .font(.callout)
                                        Image(systemName: "arrow.turn.right.up")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding()
                .background() {
                    RoundedRectangle(cornerRadius: standardPadding)
                        .fill(Asset.Colors.accent.swiftUIColor.opacity(0.2))
                }
                .foregroundColor(Asset.Colors.accent.swiftUIColor)
                .padding()
            }
            
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
                Image(systemName: "globe.europe.africa.fill")
            }
        }
        
        var titleText: String {
            switch self {
            case .username:
                L10nLookup.Scene.Profile.HandleExplainerView.exampleUsernameLabel
            case .server:
                L10nLookup.Scene.Profile.HandleExplainerView.exampleServerLabel
            }
        }
        
        var text: String {
            switch self {
            case .username(let username):
                if let username {
                    return L10nLookup.Scene.Profile.HandleExplainerView.usernameDetailWithExample(username: "@"+username)
                } else {
                    return L10nLookup.Scene.Profile.HandleExplainerView.usernameDetailWithoutExample
                }
            case .server(let serverName, let isMyServer):
                if let serverName {
                    return L10nLookup.Scene.Profile.HandleExplainerView.serverDetailWithExample(serverName: serverName) + (isMyServer ? " " + L10nLookup.Scene.Profile.HandleExplainerView.serverDetailIsMyServer(serverName: serverName) : "")
                } else {
                    return L10nLookup.Scene.Profile.HandleExplainerView.serverDetailWithoutExample
                }
            }
        }
    }
    
    @ViewBuilder func explainerRow(_ type: ExplainerRowType) -> some View {
        HStack(alignment: .top) {
            type.image
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(Asset.Colors.accent.swiftUIColor)
            VStack(alignment: .leading) {
                Text(type.titleText)
                    .font(.title2)
                Text(type.text)
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
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
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
                .glassEffectIfAvailable()
            }
        }
    }
}

struct ProfileActionBar: View {
    @Environment(ProfileViewModel.self) var viewModel
    @Environment(RelationshipViewModel.self) var relationshipViewModel
    
    var body: some View {
        HStack(spacing: standardPadding) {
            if let account = viewModel.account {
                relationshipViewModel.button.largeButton {
                    Task {
                        try await relationshipViewModel.doRelationshipAction(relationshipViewModel.button.buttonAction, account: account)
                    }
                }
                .glassEffectIfAvailable()
                
                Button() {
                    
                } label: {
                    ZStack {
                        Circle()
                            .fill(.clear)
                            .frame(width: 48, height: 48)
                        Image(systemName: "at")
                    }
                }
                .glassEffectIfAvailable()
                
                Button() {
                    
                } label: {
                    ZStack {
                        Circle()
                            .fill(.clear)
                            .frame(width: 48, height: 48)
                        Image(systemName: "ellipsis")
                    }
                }
                .glassEffectIfAvailable()
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

@MainActor
@Observable class ProfileViewModel {
    let relationshipViewModel = RelationshipViewModel()
    
    struct HandleDetails {
        let username: String
        let domain: String
        let isMyDomain: Bool
    }
    var account: MastodonAccount?
    var relationship: MastodonAccount.Relationship?
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
    var selectedPage: ProfilePage = .activity
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
    case admin
    case moderator
    case pinned
}

extension ProfileBadge: View {
    
    var icon: Image {
        switch self {
        case .admin:
            return Asset.Scene.Profile.profileBadgeAdmin.swiftUIImage
        case .moderator:
            return Asset.Scene.Profile.profileBadgeModerator.swiftUIImage
        case .pinned:
            return Image(systemName: "pin")
        }
    }
    
    var text: String {
        switch self {
        case .admin:
            L10nLookup.Scene.Profile.Badge.admin
        case .moderator:
            L10nLookup.Scene.Profile.Badge.moderator
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
