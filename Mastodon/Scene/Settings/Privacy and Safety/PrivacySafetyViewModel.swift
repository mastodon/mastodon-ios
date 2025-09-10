// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonLocalization
import MastodonCore
import MastodonSDK

protocol PrivacySafetySettingApplicable {
    var visibility: PrivacySafetyViewModel.Visibility { get }
    var manuallyApproveFollowRequests: Bool { get }
    var showFollowersAndFollowing: Bool { get }
    var suggestMyAccountToOthers: Bool { get }
    var appearInSearches: Bool { get }
}

class PrivacySafetyViewModel: ObservableObject, PrivacySafetySettingApplicable {
    enum Preset {
        case openPublic, privateRestricted, custom
    }
    
    enum Visibility: CaseIterable {
        case `public`, unlisted, followersOnly, onlyPeopleMentioned
        
        var title: String {
            switch self {
            case .public:
                return L10n.Scene.Compose.Visibility.public
            case .unlisted:
                return L10n.Scene.Compose.Visibility.unlisted
            case .followersOnly:
                return L10n.Scene.Compose.Visibility.private
            case .onlyPeopleMentioned:
                return L10n.Scene.Compose.Visibility.direct
            }
        }
        
        static func fromPrivacy(_ privacy: Mastodon.Entity.Source.Privacy) -> Self {
            switch privacy {
            case .public:
                return .public
            case .unlisted:
                return .unlisted
            case .private:
                return .followersOnly
            case .direct:
                return .onlyPeopleMentioned
            case ._other(_):
                return .public
            }
        }
        
        func toPrivacy() -> Mastodon.Entity.Source.Privacy {
            switch self {
            case .public:
                return .public
            case .unlisted:
                return .unlisted
            case .followersOnly:
                return .private
            case .onlyPeopleMentioned:
                return .direct
            }
        }
    }
    
    private var appContext: AppContext?
    private var authenticationBox: MastodonAuthenticationBox?
    private var coordinator: SceneCoordinator?
    
    public var canSetQuotability: Bool {
        return authenticationBox?.authentication.instanceConfiguration?.isAvailable(.quotePostSettings) ?? false
    }

    init(appContext: AppContext?, authenticationBox: MastodonAuthenticationBox?, coordinator: SceneCoordinator?) {
        self.appContext = appContext
        self.authenticationBox = authenticationBox
        self.coordinator = coordinator
    }

    @Published var preset: Preset = .openPublic {
        didSet { applyPreset(preset) }
    }
    @Published var visibility: Visibility = .public {
        didSet { evaluatePreset() }
    }
    @Published var quotability: Mastodon.Entity.Source.QuotePolicy = .anyone {
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
            self.apply(from: .openPublic)
        case .privateRestricted:
            self.apply(from: .privateRestricted)
        case .custom:
            break
        }
    }
    
    func evaluatePreset() {
        guard !doNotEvaluate else { return }
        if PrivacySafetySettingPreset.openPublic.equalsSettings(of: self) {
            preset = .openPublic
        } else if PrivacySafetySettingPreset.privateRestricted.equalsSettings(of: self) {
            preset = .privateRestricted
        } else {
            preset = .custom
        }
    }

    private func loadSettings() {
        Task { @MainActor in
            guard let appContext, let authenticationBox else {
                return dismiss()
            }
            
            let domain = authenticationBox.domain
            let userAuthorization = authenticationBox.userAuthorization
            
            let (account, _) = try await APIService.shared.verifyAndActivateUser(
                domain: domain,
                clientID: authenticationBox.authentication.clientID,
                clientSecret: authenticationBox.authentication.clientSecret,
                authorization: userAuthorization
            )
            
            if let privacy = account.source?.privacy {
                visibility = .fromPrivacy(privacy)
            }
            
            manuallyApproveFollowRequests = account.locked == true
            showFollowersAndFollowing = account.source?.hideCollections == false
            suggestMyAccountToOthers = account.source?.discoverable == true
            appearInSearches = account.source?.indexable == true

            isUserInteractionEnabled = true
        }
    }
    
    func saveSettings() {
        Task {
            guard let authenticationBox else {
                return
            }
    
            let domain = authenticationBox.domain
            let userAuthorization = authenticationBox.userAuthorization
            
            let quotabilityToSet = canSetQuotability ? quotability : nil
            do {
                let updatedAccount = try await APIService.shared.accountUpdateCredentials(
                    domain: domain,
                    query: .init(
                        discoverable: suggestMyAccountToOthers,
                        locked: manuallyApproveFollowRequests,
                        source: .withPrivacy(visibility.toPrivacy(), quotePolicy: quotabilityToSet),
                        indexable: appearInSearches,
                        hideCollections: !showFollowersAndFollowing
                    ),
                    authorization: userAuthorization
                )
            } catch {
                // TODO: communicate error
            }
        }
    }
    
    func dismiss() {
        onDismiss.send(())
    }
}

// Preset Rules Definition
extension PrivacySafetyViewModel {
    private func apply(from source: PrivacySafetySettingPreset) {
        doNotEvaluate = true
        visibility = source.visibility
        manuallyApproveFollowRequests = source.manuallyApproveFollowRequests
        showFollowersAndFollowing = source.showFollowersAndFollowing
        suggestMyAccountToOthers = source.suggestMyAccountToOthers
        appearInSearches = source.appearInSearches
        doNotEvaluate = false
    }
}
