// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

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
    
    var quotability: Mastodon.Entity.Source.QuotePolicy {
        switch self {
        case .openPublic:
            return .anyone
        case .privateRestricted:
            return .nobody
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
            viewModel.quotability == quotability &&
            viewModel.manuallyApproveFollowRequests == manuallyApproveFollowRequests &&
            viewModel.showFollowersAndFollowing == showFollowersAndFollowing &&
            viewModel.suggestMyAccountToOthers == suggestMyAccountToOthers &&
            viewModel.appearInSearches == appearInSearches
    }
}
