// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import SDWebImageSwiftUI
import SwiftUI
import MastodonCore
import MastodonSDK

class ProfileHostingViewController: UIHostingController<AnyView> {
    let viewModel = ProfileViewModel()
    let relationshipViewModel = RelationshipViewModel()
    let nestedScrollViewModel = NestedScrollInteractionViewModel()
    
    init(wrapInNavigationController: Bool) {
        let root = ProfileView(wrapInNavigationController: wrapInNavigationController).environment(viewModel).environment(relationshipViewModel).environment(nestedScrollViewModel)
        super.init(rootView: AnyView(root))
        title = nil
    }
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func set(account: MastodonAccount, relationship: MastodonAccount.Relationship) {
        viewModel.account = account
        viewModel.relationship = relationship
        viewModel.postsViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: .init(excludeReplies: true)), asyncRefreshViewModel: AsyncRefreshViewModel())
        viewModel.postsAndRepliesViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: .init(excludeReplies: false)), asyncRefreshViewModel: AsyncRefreshViewModel())
        viewModel.mediaViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: .init(onlyMedia: true)), asyncRefreshViewModel: AsyncRefreshViewModel())
        relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: account.locked)
    }
}

struct ProfileView: View {
    @Environment(ProfileViewModel.self) var viewModel
    @Environment(NestedScrollInteractionViewModel.self) var nestedScrollViewModel
    let wrapInNavigationController: Bool
    
    @State var isPresentingActivityFilter: Bool = false
    
    enum Subview: Hashable {
        case bannerAndAvatar
        case bio
        case paginationControl
        case repliesAndBoostsFilterButton
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
                    
                    Spacer()
                        .frame(height: doublePadding)
                    
                    subview(.paginationControl, width: geo.size.width)
                        .id(Subview.paginationControl)
                        .frame(width: min(maxFeedContentWidth, geo.size.width))
                    Divider()
                    
                    if viewModel.selectedPage == .activity {
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: doublePadding)
                            
                            subview(.repliesAndBoostsFilterButton, width: geo.size.width)
                                .padding(.horizontal, doublePadding)
                                .id(Subview.repliesAndBoostsFilterButton)
                                .frame(width: min(maxFeedContentWidth, geo.size.width))
                            
                            Spacer()
                                .frame(height: doublePadding)
                        }
                        .transition(.move(edge: .leading))
                        .transition(.push(from: .trailing))
                    }
                    
                    subview(.pages, width: geo.size.width)
                        .id(Subview.pages)
                        .frame(height: geo.size.height - geo.safeAreaInsets.top)
                }
            }
            .nestedScrollview(.outer)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder func subview(_ subviewType: Subview, width: CGFloat) -> some View {
        switch subviewType {
        case .bannerAndAvatar:
            ProfileAvatarAndBannerView(width: width)
        case .bio:
            ProfileInfoView()
        case .paginationControl:
            ProfilePaginationControl()
            .frame(width: min(width, maxFeedContentWidth))
        case .repliesAndBoostsFilterButton:
            HStack() {
                Button() {
                    isPresentingActivityFilter = !isPresentingActivityFilter
                } label: {
                    HStack() {
                        Text(viewModel.activityFilterButtonTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .padding(tinySpacing)
                            .background() {
                                Circle()
                                    .fill(.secondary.quinary)
                            }
                    }
                }
                .popover(isPresented: $isPresentingActivityFilter, arrowEdge: .top) {
                    VStack {
                        Toggle(L10nLookup.Scene.Profile.ActivityFilter.showRepliesToggleLabel,
                               isOn: Binding<Bool>(
                                get: { viewModel.includeReplies },
                                set: { newValue in viewModel.includeReplies = newValue}
                               )
                        )
                        .tint(Asset.Colors.accent.swiftUIColor)
                        Toggle(L10nLookup.Scene.Profile.ActivityFilter.showBoostsToggleLabel,
                               isOn: Binding<Bool>(
                                get: { viewModel.includeBoosts },
                                set: { newValue in viewModel.includeBoosts = newValue}
                               )
                        )
                        .tint(Asset.Colors.accent.swiftUIColor)
                        Spacer()
                            .frame(maxHeight: .infinity)
                    }
                    .padding(doublePadding * 2)
                    .presentationDetents([.fraction(0.25)])
                }
                
                Spacer()
                    .frame(maxWidth: .infinity)
            }
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
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            
            VStack(alignment: .leading) {
                MastodonContentView.header(html: viewModel.account?.displayInfo.displayName ?? "No Name", emojis: viewModel.account?.displayInfo.emojis ?? [], style: .profileDisplayName)
                Text(viewModel.account?.displayInfo.fullHandle ?? "@unknown")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                                .environment(AsyncRefreshViewModel())
                                .tag(page)
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .mediaOnly:
                            TimelineListView()
                                .environment(viewModel.mediaViewModel)
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

@Observable class ProfileViewModel {
    var account: MastodonAccount?
    var relationship: MastodonAccount.Relationship?
    var postsViewModel: TimelineListViewModel?
    var postsAndRepliesViewModel: TimelineListViewModel?
    var mediaViewModel: TimelineListViewModel?
    var selectedPage: ProfilePage = .activity
    
    var includeBoosts: Bool = true
    var includeReplies: Bool = false

    var activityFilterButtonTitle: String {
        switch (includeBoosts, includeReplies) {
        case (true, true):
            L10nLookup.Scene.Profile.ActivityFilter.includeBoostsAndReplies
        case (false, false):
            L10nLookup.Scene.Profile.ActivityFilter.directPostsOnly
        case (false, true):
            L10nLookup.Scene.Profile.ActivityFilter.includeReplies
        case (true, false):
            L10nLookup.Scene.Profile.ActivityFilter.includeBoosts
        }
    }
    
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
