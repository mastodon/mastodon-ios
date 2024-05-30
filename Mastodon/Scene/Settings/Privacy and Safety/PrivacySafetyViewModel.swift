// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonLocalization
import MastodonCore
import MastodonSDK

class PrivacySafetyViewModel: ObservableObject {
    enum Preset {
        case openPublic, privateRestricted, custom
    }
    
    enum Visibility: CaseIterable {
        case `public`, followersOnly, onlyPeopleMentioned
        
        var title: String {
            switch self {
            case .public:
                return L10n.Scene.Settings.PrivacySafety.DefaultPostVisibility.public
            case .followersOnly:
                return L10n.Scene.Settings.PrivacySafety.DefaultPostVisibility.followersOnly
            case .onlyPeopleMentioned:
                return L10n.Scene.Settings.PrivacySafety.DefaultPostVisibility.onlyPeopleMentioned
            }
        }
        
        static func from(_ privacy: Mastodon.Entity.Source.Privacy) -> Self {
            switch privacy {
            case .public:
                return .public
            case .unlisted:
                return .followersOnly
            case .private, .direct:
                return .onlyPeopleMentioned
            case ._other(_):
                return .public
            }
        }
        
        func toPrivacy() -> Mastodon.Entity.Source.Privacy {
            switch self {
            case .public:
                return .public
            case .followersOnly:
                return .unlisted
            case .onlyPeopleMentioned:
                return .private
            }
        }
    }
    
    private var appContext: AppContext?
    private var authContext: AuthContext?
    private var coordinator: SceneCoordinator?

    init(appContext: AppContext?, authContext: AuthContext?, coordinator: SceneCoordinator?) {
        self.appContext = appContext
        self.authContext = authContext
        self.coordinator = coordinator
    }

    @Published var preset: Preset = .openPublic {
        didSet { applyPreset(preset) }
    }
    @Published var visibility: Visibility = .public {
        didSet { evaluatePreset() }
    }
    
    @Published var manuallyApproveFollowRequests = false {
        didSet { evaluatePreset() }
    }
    
    @Published var showFollowersAndFollowing = true {
        didSet { evaluatePreset() }
    }
    
    @Published var suggestMyAccountToOthers = true {
        didSet { evaluatePreset() }
    }
    
    @Published var appearInSearches = true {
        didSet { evaluatePreset() }
    }
    
    private var doNotEvaluate = true
    @Published var isUserInteractionEnabled = false
    let onDismiss = PassthroughSubject<Void, Never>()
    
    func viewDidAppear() {
        doNotEvaluate = false
        if !isUserInteractionEnabled {
            loadSettings()
        }
    }
}

extension PrivacySafetyViewModel: Equatable {
    static func == (lhs: PrivacySafetyViewModel, rhs: PrivacySafetyViewModel) -> Bool {
        lhs.visibility == rhs.visibility &&
        lhs.manuallyApproveFollowRequests == rhs.manuallyApproveFollowRequests &&
        lhs.showFollowersAndFollowing == rhs.showFollowersAndFollowing &&
        lhs.suggestMyAccountToOthers == rhs.suggestMyAccountToOthers &&
        lhs.appearInSearches == rhs.appearInSearches
    }
}

extension PrivacySafetyViewModel {
    func applyPreset(_ preset: Preset) {
        switch preset {
        case .openPublic:
            PrivacySafetyViewModel.openPublic.apply(to: self)
        case .privateRestricted:
            PrivacySafetyViewModel.privateRestricted.apply(to: self)
        case .custom:
            break
        }
    }
    
    func evaluatePreset() {
        guard !doNotEvaluate else { return }
        if self == Self.openPublic {
            preset = .openPublic
        } else if self == Self.privateRestricted {
            preset = .privateRestricted
        } else {
            preset = .custom
        }
    }

    func loadSettings() {
        Task { @MainActor in
            guard let appContext, let authContext else {
                return dismiss()
            }
            
            let domain = authContext.mastodonAuthenticationBox.domain
            let userAuthorization = authContext.mastodonAuthenticationBox.userAuthorization
            
            let account = try await appContext.apiService.accountVerifyCredentials(
                domain: domain,
                authorization: userAuthorization
            ).singleOutput().value
            
            if let privacy = account.source?.privacy {
                visibility = .from(privacy)
            }
            
            manuallyApproveFollowRequests = account.locked == true
            showFollowersAndFollowing = account.hideCollections == false
            suggestMyAccountToOthers = account.discoverable == true
            appearInSearches = account.indexable == true

            isUserInteractionEnabled = true
        }
    }
    
    func saveSettings() {
        Task {
            guard let appContext, let authContext else {
                return
            }
    
            let domain = authContext.mastodonAuthenticationBox.domain
            let userAuthorization = authContext.mastodonAuthenticationBox.userAuthorization
            
            let _ = try await appContext.apiService.accountUpdateCredentials(
                domain: domain,
                query: .init(
                    discoverable: suggestMyAccountToOthers,
                    locked: manuallyApproveFollowRequests,
                    source: .withPrivacy(visibility.toPrivacy()),
                    indexable: appearInSearches,
                    hideCollections: !showFollowersAndFollowing
                ),
                authorization: userAuthorization
            ).value
        }
    }
    
    func dismiss() {
        onDismiss.send(())
    }
}

// Preset Rules Definition
extension PrivacySafetyViewModel {
    static let openPublic: PrivacySafetyViewModel = {
        let vm = PrivacySafetyViewModel(appContext: nil, authContext: nil, coordinator: nil)
        vm.visibility = .public
        vm.manuallyApproveFollowRequests = false
        vm.showFollowersAndFollowing = true
        vm.suggestMyAccountToOthers = true
        vm.appearInSearches = true
        return vm
    }()
    
    static let privateRestricted: PrivacySafetyViewModel = {
        let vm = PrivacySafetyViewModel(appContext: nil, authContext: nil, coordinator: nil)
        vm.visibility = .followersOnly
        vm.manuallyApproveFollowRequests = true
        vm.showFollowersAndFollowing = false
        vm.suggestMyAccountToOthers = false
        vm.appearInSearches = false
        return vm
    }()
    
    private func apply(to target: PrivacySafetyViewModel) {
        target.doNotEvaluate = true
        target.visibility = self.visibility
        target.manuallyApproveFollowRequests = self.manuallyApproveFollowRequests
        target.showFollowersAndFollowing = self.showFollowersAndFollowing
        target.suggestMyAccountToOthers = self.suggestMyAccountToOthers
        target.appearInSearches = self.appearInSearches
        target.doNotEvaluate = false
    }
}
