// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonSDK

struct ServerDetailsView: View {
    @State var selectedTab = ServerDetailsTab.about
    @State var viewModel = ServerDetailsViewModel()
    
    var body: some View {
        Group {
            switch selectedTab {
            case .about:
                    Text("ABOUT")
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
            }
        }
    }
    var instance: Mastodon.Entity.V2.Instance?
    
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
