// Copyright © 2024 Mastodon gGmbH. All rights reserved.

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
    }
    
    weak var appContext: AppContext?
    
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
    @Published var isInitialized = false
    
    func viewDidAppear() {
        doNotEvaluate = false
        if !isInitialized {
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
            
            
            isInitialized = true
        }
    }
    
    func saveSettings() {
        Task {
            
        }
    }
}

// Preset Rules Definition
extension PrivacySafetyViewModel {
    static let openPublic: PrivacySafetyViewModel = {
        let vm = PrivacySafetyViewModel()
        vm.visibility = .public
        vm.manuallyApproveFollowRequests = false
        vm.showFollowersAndFollowing = true
        vm.suggestMyAccountToOthers = true
        vm.appearInSearches = true
        return vm
    }()
    
    static let privateRestricted: PrivacySafetyViewModel = {
        let vm = PrivacySafetyViewModel()
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
