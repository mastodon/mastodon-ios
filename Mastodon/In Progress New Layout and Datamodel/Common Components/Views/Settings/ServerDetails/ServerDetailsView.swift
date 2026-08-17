// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonLocalization
import MastodonSDK
import MastodonUI
import SDWebImageSwiftUI

enum ServerDetailsTab: Int, CaseIterable {
    case about = 0
    case rules = 1
    
    var title: String {
        switch self {
        case .about: return L10n.Scene.Settings.ServerDetails.about
        case .rules: return L10n.Scene.Settings.ServerDetails.rules
        }
    }
}

struct ServerDetailsView: View {
    @State var selectedTab = ServerDetailsTab.about
    @State var viewModel = ServerDetailsViewModel()
    
    var body: some View {
        Group {
            switch selectedTab {
            case .about:
                    AboutInstanceView()
                    .environment(viewModel)
            case .rules:
                MastodonServerRulesView(viewModel: .init(disclaimer: nil, rules: viewModel.rulesModel.rules, onAgree: nil, onDisagree: nil))
                    .padding(.top)
            }
        }
        .navigationTitle(AuthenticationObserver.shared.currentActiveUser?.domain ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            Picker("", selection: $selectedTab) {
                ForEach(ServerDetailsTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .task() {
            viewModel.authBox = AuthenticationObserver.shared.currentActiveUser
        }
    }
}

@MainActor
@Observable class ServerDetailsViewModel {
    var authBox: MastodonAuthenticationBox? {
        didSet {
            Task {
                guard let domain = authBox?.domain else { return }
                do {
                    self.instance = try await APIService.shared.instanceV2(domain: domain, authenticationBox: authBox).singleOutput().value
                } catch {
                    // TODO: handle error?
                }
                
                do {
                    self.extendedDescription = try await APIService.shared.extendedDescription(domain: domain, authenticationBox: authBox).singleOutput().value
                } catch {
                    // TODO: handle error?
                }
            }
        }
    }
    var instance: Mastodon.Entity.V2.Instance?
    var extendedDescription: Mastodon.Entity.ExtendedDescription?
    
    var rulesModel: InstanceRulesViewModel {
        InstanceRulesViewModel(disclaimer: nil, rules: instance?.rules ?? [], onAgree: nil, onDisagree: nil)
    }
}

@MainActor
@Observable class InstanceRulesViewModel {
    let disclaimer: LocalizedStringKey?
    let rules: [Mastodon.Entity.Instance.Rule]
    var onAgree: (() -> Void)?
    var onDisagree: (() -> Void)?
    
    init(disclaimer: LocalizedStringKey?, rules: [Mastodon.Entity.Instance.Rule], onAgree: (() -> Void)?, onDisagree: (() -> Void)?) {
        self.disclaimer = disclaimer
        self.rules = rules
        self.onAgree = onAgree
        self.onDisagree = onDisagree
    }
    
    fileprivate static var empty: InstanceRulesViewModel {
        return .init(disclaimer: nil, rules: [], onAgree: nil, onDisagree: nil)
    }
}

struct AboutInstanceView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(ServerDetailsViewModel.self) var serverDetailsViewModel
    
    var body: some View {
        GeometryReader() { geoProxy in
            let readableWidth = min(geoProxy.size.width - doublePadding * 2, maxFeedContentWidth)
            ScrollView {
                VStack(alignment: .leading) {
                    if let instance = serverDetailsViewModel.instance {
                        
                        // Title
                        Text(instance.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        
                        // Image
                        if let thumbnailString = instance.thumbnail?.url, let thumbnailUrl = URL(string: thumbnailString) {
                            WebImage(
                                url: thumbnailUrl,
                                content: { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                },
                                placeholder: {
                                }
                            )
                            .frame(height: 160)
                            .clipped()
                            .clipShape(.rect(cornerRadius: 12)) // TODO: standarized radius
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Administrator
                        if let admin = serverDetailsViewModel.instance?.contact?.account, let domain = serverDetailsViewModel.instance?.domain {
                            let adminAccount = MastodonAccount.fromEntity(admin, authenticatedDomain: domain)
                            
                            Text(L10n.Scene.Settings.ServerDetails.AboutInstance.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.top)
                            
                            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                                Button {
                                    navigator.push(.profile(account: admin, relationship: nil))
                                } label: {
                                    AvatarView(style: .roundedRect, size: .large, avatarSource: .url(admin.avatarURL))
                                    AccountDisplayNameAndHandle(account: adminAccount, includeVerifiedLink: true)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.leading)
                            .frame(width: readableWidth)
                        }
                        
                        // Info
                        Text(L10n.Scene.Settings.ServerDetails.AboutInstance.legalNotice)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.vertical)
                        
                        MastodonContentView.timelinePost(html: instance.description, emojis: [], isInlinePreview: false)
                        
                        if let extended = serverDetailsViewModel.extendedDescription?.content, !extended.isEmpty {
                            
                            Divider()
                                .padding(.vertical)
                            
                            MastodonContentView.timelinePost(html: extended, emojis: [], isInlinePreview: false)
                        }
                    }
                }
                .frame(width: readableWidth)
                .padding(.horizontal, (geoProxy.size.width - readableWidth) / 2.0)
                .padding(.bottom)
            }
            .frame(width: geoProxy.size.width, height: geoProxy.size.height)
        }
    }
}
