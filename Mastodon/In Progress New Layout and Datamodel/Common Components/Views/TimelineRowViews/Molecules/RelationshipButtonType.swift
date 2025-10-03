// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import MastodonSDK
import SwiftUI

enum RelationshipButtonType {
    case updating
    case error(Error?)
    case iAmMutingThem
    case iAmBlockingThem(isDomainBlock: Bool)
    case iDoNotFollowThem(theyFollowMe: Bool, theirAccountIsLocked: Bool)
    case iFollowThem(theyFollowMe: Bool)
    case iHaveRequestedToFollowThem
    
    enum RelationshipAction {
        case follow
        case unfollow
        case unmute
        case unblock
        case noAction
        
        var mastodonPostMenuAction: MastodonPostMenuAction? {
            switch self {
            case .follow:
                return .follow
            case .unfollow:
                return .unfollow
            case .unmute:
                return .unmute
            case .unblock:
                return .unblockUser
            case .noAction:
                return nil
            }
        }
    }
    
    init(relationship: Mastodon.Entity.Relationship, theirAccountIsLocked: Bool) {
        if relationship.blocking {
            self = .iAmBlockingThem(isDomainBlock: false)
        } else if relationship.domainBlocking {
            self = .iAmBlockingThem(isDomainBlock: true)
        } else if relationship.muting {
            self = .iAmMutingThem
        } else if relationship.following {
            self = .iFollowThem(theyFollowMe: relationship.followedBy)
        } else if relationship.requested {
            self = .iHaveRequestedToFollowThem
        } else {
            self = .iDoNotFollowThem(theyFollowMe: relationship.followedBy, theirAccountIsLocked: theirAccountIsLocked)
        }
    }
    
    var description: String {
        switch self {
        case .updating:
            return "updating"
        case .error:
            return "error"
        case .iAmBlockingThem(let isDomainBlock):
            if isDomainBlock {
                return "iAmBlockingThem+isDomainBlock"
            } else {
                return "iAmBlockingThem"
            }
        case .iAmMutingThem:
            return "iAmMutingThem"
        case .iDoNotFollowThem(let theyFollowMe, let theirAccountIsLocked):
            let theyFollowMeString = theyFollowMe ? "theyFollowMe" : "theyDoNotFollowMe"
            let accountLockedString = theirAccountIsLocked ? "canRequestToFollow" : "canFollow"
            return ["iDoNotFollowThem", theyFollowMeString, accountLockedString].joined(separator: "+")
        case .iFollowThem(let theyFollowMe):
            if theyFollowMe {
                return "iFollowThem+theyFollowMe"
            } else {
                return "iFollowThem+theyDoNotFollowMe"
            }
        case .iHaveRequestedToFollowThem:
            return "iHaveRequestedToFollowThem"
        }
    }
    
    var buttonText: String? {
        switch self {
        case .iDoNotFollowThem(let theyFollowMe, let theirAccountIsLocked):
            if theirAccountIsLocked {
                return L10n.Common.Controls.Friendship.request
            } else {
                if theyFollowMe {
                    return L10n.Common.Controls.Friendship.followBack
                } else {
                    return L10n.Common.Controls.Friendship.follow
                }
            }
        case .iFollowThem(let theyFollowMe):
            if theyFollowMe {
                return L10n.Common.Controls.Friendship.mutual
            } else {
                return L10n.Common.Controls.Friendship.following
            }
        case .iHaveRequestedToFollowThem:
            return L10n.Common.Controls.Friendship.pending
        case .iAmMutingThem:
            return L10n.Common.Controls.Friendship.muted
        case .iAmBlockingThem:
            return L10n.Common.Controls.Friendship.blocked
        case .updating, .error:
            return nil
        }
    }
    
    var buttonAction: RelationshipAction {
        switch self {
        case .iDoNotFollowThem:
            return .follow
        case .iFollowThem, .iHaveRequestedToFollowThem:
            return .unfollow
        case .updating, .error(_):
            return .noAction
        case .iAmMutingThem:
            return .unmute
        case .iAmBlockingThem:
            return .unblock
        }
    }
    
    
    var a11yActionTitle: String? {
        switch self {
        case .iDoNotFollowThem:
            return buttonText
        case .iFollowThem, .iHaveRequestedToFollowThem:
            return L10n.Common.Alerts.UnfollowUser.unfollow
        case .iAmBlockingThem:
            return L10n.Common.Controls.Friendship.unblock
        case .iAmMutingThem:
            return L10n.Common.Controls.Friendship.unmute
        case .error, .updating:
            return nil
        }
    }
    
    @ViewBuilder func button(action: @escaping ()->()) -> some View {
        switch self {
        case .updating:
            ProgressView().progressViewStyle(.circular)
        case .error:
            lightwieghtImageView(
                "exclamationmark.triangle", size: AvatarSize.small)
        default:
            if let buttonText {
                Button(buttonText) {
                    action()
                }
                .buttonStyle(RelationshipButtonStyle(self))
            }
        }
    }
}
