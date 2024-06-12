// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

enum PrivacySafetySettingPreset: PrivacySafetySettingApplicable {
    case openPublic, privateRestricted
    
    var visibility: PrivacySafetyViewModel.Visibility {
        switch self {
        case .openPublic:
            return .public
        case .privateRestricted:
            return .followersOnly
        }
    }
    
    var manuallyApproveFollowRequests: Bool {
        switch self {
        case .openPublic:
            return false
        case .privateRestricted:
            return true
        }
    }
    
    var showFollowersAndFollowing: Bool {
        switch self {
        case .openPublic:
            return true
        case .privateRestricted:
            return false
        }
    }
    
    var suggestMyAccountToOthers: Bool {
        switch self {
        case .openPublic:
            return true
        case .privateRestricted:
            return false
        }
    }
    
    var appearInSearches: Bool {
        switch self {
        case .openPublic:
            return true
        case .privateRestricted:
            return false
        }
    }
    
    func equalsSettings(of viewModel: PrivacySafetyViewModel) -> Bool {
        return viewModel.visibility == visibility &&
            viewModel.manuallyApproveFollowRequests == manuallyApproveFollowRequests &&
            viewModel.showFollowersAndFollowing == showFollowersAndFollowing &&
            viewModel.suggestMyAccountToOthers == suggestMyAccountToOthers &&
            viewModel.appearInSearches == appearInSearches
    }
}
