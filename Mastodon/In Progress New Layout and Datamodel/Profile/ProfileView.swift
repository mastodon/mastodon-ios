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
    
    init(wrapInNavigationController: Bool) {
        let root = ProfileView(wrapInNavigationController: wrapInNavigationController).environment(viewModel).environment(relationshipViewModel)
        super.init(rootView: AnyView(root))
        title = nil
        navigationItem.rightBarButtonItems = viewModel.navigationButtons
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
        navigationItem.rightBarButtonItems = viewModel.navigationButtons
    }
}

struct ProfileView: View {
    @Environment(ProfileViewModel.self) var viewModel
    let wrapInNavigationController: Bool
    
    enum Subview: Hashable {
        case bannerAndAvatar
        case bio
        case paginationControl
        case pages
    }
    
    var body: some View {
        if wrapInNavigationController {
            NavigationStack() {
                content
                    .toolbar {
                        if let relationship = viewModel.relationship {
                            viewModel.toolbar(relationship: relationship)
                        }
                    }
                    .toolbarBackground(.clear, for: .navigationBar)
            }
        } else {
            content
                .toolbar {
                    if let relationship = viewModel.relationship {
                        viewModel.toolbar(relationship: relationship)
                    }
                }
                .toolbarBackground(.clear, for: .navigationBar)
        }
    }
    
    @ViewBuilder var content: some View {
        GeometryReader { geo in
            ScrollView() {
                VStack(alignment: .center, spacing: 0) {
                    subview(.bannerAndAvatar, geometry: geo)
                        .id(Subview.bannerAndAvatar)
                    Spacer()
                        .frame(height: doublePadding)
                    subview(.bio, geometry: geo)
                        .id(Subview.bio)
                        .padding(.horizontal, doublePadding)
                        .frame(width: min(maxFeedContentWidth, geo.size.width))
                    Spacer()
                        .frame(height: doublePadding)
                    
                    subview(.paginationControl, geometry: geo)
                        .id(Subview.paginationControl)
                    subview(.pages, geometry: geo)
                        .id(Subview.pages)
                        .frame(height: geo.size.height)
                }
                .scrollTargetLayout()
            }
            .frame(height: geo.size.height)
            .onScrollTargetVisibilityChange(idType: Subview.self) { visible in
                let paginatingControlIsNotVisible = !visible.contains(.paginationControl)
                if paginatingControlIsNotVisible != viewModel.postsViewModel?.isScrollEnabled {
                    viewModel.postsViewModel?.isScrollEnabled = paginatingControlIsNotVisible
                    viewModel.postsAndRepliesViewModel?.isScrollEnabled = paginatingControlIsNotVisible
                    viewModel.mediaViewModel?.isScrollEnabled = paginatingControlIsNotVisible
                }
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder func subview(_ subviewType: Subview, geometry geo: GeometryProxy) -> some View {
        switch subviewType {
        case .bannerAndAvatar:
            ProfileAvatarAndBannerView(width: geo.size.width)
        case .bio:
            ProfileInfoView()
        case .paginationControl:
            Picker("", selection: Binding<ProfilePage>(
                get: { viewModel.selectedPage },
                set: { newValue in viewModel.selectedPage = newValue }
            )) {
                ForEach(ProfilePage.allCases, id: \.self) { page in
                    Text(page.title)
                }
            }
            .pickerStyle(.segmented)
        case .pages:
            ProfilePaginatingView()
        }
    }
}

let bannerFullHeight: CGFloat = 200
struct ProfileAvatarAndBannerView: View {
    @Environment(ProfileViewModel.self) var viewModel
    var width: CGFloat
    
    var body: some View {
        VStack {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)) {
                VStack(spacing: doublePadding) {
                    bannerView()
                        .frame(width: width, height: bannerFullHeight)
                        .clipped()
                    HStack {
                        Spacer()
                            .frame(maxWidth: .infinity)
                        AccountStatsView(accountMetrics: viewModel.account?.metrics) { stat in
                            switch stat {
                            case .postCount:
                                break
                            case .followersCount:
                                break
                            case .followingCount:
                                break
                            }
                        }
                        .padding(.trailing, doublePadding)
                    }
                    .frame(maxWidth: maxFeedContentWidth)
                }
                HStack() {
                    Spacer()
                        .frame(maxWidth: .infinity)
                    AvatarView(size: .extraLarge, authorAvatarUrl: viewModel.account?.avatarURL, goToProfile: nil)
                        .padding(.horizontal, doublePadding)
                        .frame(width: min(maxFeedContentWidth, width), alignment: .leading)
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    @ViewBuilder func bannerView() -> some View {
        if let bannerUrl = viewModel.account?.displayInfo.bannerImageUrl {
            WebImage(url: bannerUrl) { phase in
                switch phase {
                case .empty:
                    EmptyView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
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
                        if let account = viewModel.account {
                            relationshipViewModel.button.button {
                                Task {
                                    try await relationshipViewModel.doRelationshipAction(relationshipViewModel.button.buttonAction, account: account)
                                }
                            }
                        }
                    }
                }
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
                        case .posts:
                            TimelineListView()
                                .environment(viewModel.postsViewModel)
                                .environment(AsyncRefreshViewModel())
                                .tag(page)
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .postsAndReplies:
                            TimelineListView()
                                .environment(viewModel.postsAndRepliesViewModel)
                                .environment(AsyncRefreshViewModel())
                                .tag(page)
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .mediaOnly:
                            TimelineListView()
                                .environment(viewModel.mediaViewModel)
                                .environment(AsyncRefreshViewModel())
                                .tag(page)
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .profileInfo:
                            page.color
                                .tag(page)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                      
                    }
                }
                .tabViewStyle(.page)
        }
    }
}

enum ProfilePage: CaseIterable, Hashable {
    case posts
    case postsAndReplies
    case mediaOnly
    case profileInfo
    
    var title: String {
        switch self {
        case .posts:
            L10n.Scene.Profile.SegmentedControl.posts
        case .postsAndReplies:
            L10n.Scene.Profile.SegmentedControl.postsAndReplies
        case .mediaOnly:
            L10n.Scene.Profile.SegmentedControl.media
        case .profileInfo:
            L10n.Scene.Profile.SegmentedControl.about
        }
    }
    
    var nextPage: ProfilePage {
        switch self {
        case .posts:
                .postsAndReplies
        case .postsAndReplies:
                .mediaOnly
        case .mediaOnly:
                .profileInfo
        case .profileInfo:
                .posts
        }
    }
    
    var color: Color {
        switch self {
        case .posts:
                .blue
        case .postsAndReplies:
                .orange
        case .mediaOnly:
                .green
        case .profileInfo:
                .red
        }
    }
}

@Observable class ProfileViewModel {
    var account: MastodonAccount?
    var relationship: MastodonAccount.Relationship?
    var postsViewModel: TimelineListViewModel?
    var postsAndRepliesViewModel: TimelineListViewModel?
    var mediaViewModel: TimelineListViewModel?
    var selectedPage: ProfilePage = .posts
    
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
