// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import MastodonSDK
import MastodonUI
import SwiftUI

enum RelationshipButtonType {
    case updating
    case error(Error?)
    case iAmMutingThem
    case iAmBlockingThem(isDomainBlock: Bool)
    case iDoNotFollowThem(theyFollowMe: Bool, theirAccountIsLocked: Bool)
    case iFollowThem(theyFollowMe: Bool)
    case iHaveRequestedToFollowThem
    case rejectTheirFollowRequest
    case acceptTheirFollowRequest
    case edit
    case hiddenByModerators
    
    enum RelationshipAction {
        case editProfile
        case follow
        case unfollow
        case unmute
        case unblock
        case approveFollowRequest
        case rejectFollowRequest
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
            case .noAction, .editProfile, .approveFollowRequest, .rejectFollowRequest:
                return nil
            }
        }
        
        var mastodonRelationshipMenuAction: MastodonMenuAction.RelationshipMenuAction? {
            switch self {
            case .follow:
                return .follow
            case .unfollow:
                return .unfollow
            case .unmute:
                return .unmute
            case .unblock:
                return .unblockUser
            case .noAction, .editProfile, .approveFollowRequest, .rejectFollowRequest:
                return nil
            }
        }
    }
    
    init(relationship: Mastodon.Entity.Relationship, theirAccountIsLocked: Bool) {
        if relationship.blocking {
            self = .iAmBlockingThem(isDomainBlock: false)
        } else if relationship.domainBlocking {
            self = .iAmBlockingThem(isDomainBlock: true)
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
        case .edit:
            return "edit"
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
        case .hiddenByModerators:
            return "hiddenByModerators"
        case .acceptTheirFollowRequest:
            return "acceptTheirFollowRequest"
        case .rejectTheirFollowRequest:
            return "rejectTheirFollowRequest"
        }
    }
    
    func buttonText(isLarge: Bool) -> String? {
        switch self {
        case .edit:
            return L10nLookup.Common.Controls.editProfileButton
        case .iDoNotFollowThem(let theyFollowMe, let theirAccountIsLocked):
            if theirAccountIsLocked {
                return L10nLookup.Common.Controls.RelationshipAction.requestToFollow(longForm: isLarge)
            } else {
                if theyFollowMe {
                    return L10nLookup.Common.Controls.RelationshipAction.followBack
                } else {
                    return L10nLookup.Common.Controls.RelationshipAction.follow
                }
            }
        case .iFollowThem:
            return L10nLookup.Common.Controls.RelationshipAction.unfollow
        case .iHaveRequestedToFollowThem:
            return L10nLookup.Common.Controls.RelationshipAction.cancelRequestToFollow(longForm: isLarge)
        case .iAmMutingThem:
            return L10nLookup.Common.Controls.RelationshipAction.unmute
        case .iAmBlockingThem:
            return L10nLookup.Common.Controls.RelationshipAction.unblock
        case .updating, .error:
            return nil
        case .hiddenByModerators:
            return L10nLookup.Common.Controls.RelationshipAction.showAnyway
        case .acceptTheirFollowRequest:
            return L10nLookup.Common.Controls.RelationshipAction.acceptFollowRequest
        case .rejectTheirFollowRequest:
            return L10nLookup.Common.Controls.RelationshipAction.rejectFollowRequest
        }
    }
    
    var buttonAction: RelationshipAction {
        switch self {
        case .edit:
            return .editProfile
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
        case .hiddenByModerators:
            return .noAction
        case .acceptTheirFollowRequest:
            return .approveFollowRequest
        case .rejectTheirFollowRequest:
            return .rejectFollowRequest
        }
    }
    
    
    var a11yActionTitle: String? {
        switch self {
        case .error, .updating:
            return nil
        default:
            return buttonText(isLarge: true)
        }
    }
    
    @ViewBuilder func button(isOpaque: Bool, action: @escaping ()->()) -> some View {
        switch self {
        case .updating:
            Button() {
                // nothing to do
            } label: {
                ProgressView().progressViewStyle(.circular)
            }
            .buttonStyle(RelationshipButtonStyle(self, isLarge: false, isOpaque: isOpaque))
        case .error:
            Button() {
                // nothing to do
            } label: {
                lightwieghtImageView("exclamationmark.triangle", size: AvatarSize.tiny)
            }
            .buttonStyle(RelationshipButtonStyle(self, isLarge: false, isOpaque: isOpaque))
        default:
            if let buttonText = buttonText(isLarge: false) {
                Button(buttonText) {
                    action()
                }
                .buttonStyle(RelationshipButtonStyle(self, isLarge: false, isOpaque: isOpaque))
            }
        }
    }
    
    @ViewBuilder func largeButton(isOpaque: Bool, action: @escaping ()->()) -> some View {
        switch self {
        case .updating:
            Button() {
                // nothing to do
            } label: {
                ProgressView().progressViewStyle(.circular)
            }
            .buttonStyle(RelationshipButtonStyle(self, isLarge: true, isOpaque: isOpaque))
        case .error:
            Button() {
                
            } label: {
                lightwieghtImageView(
                    "exclamationmark.triangle", size: AvatarSize.tiny)
            }
            .buttonStyle(RelationshipButtonStyle(self, isLarge: true, isOpaque: isOpaque))
        default:
            if let buttonText = buttonText(isLarge: true) {
                Button(buttonText) {
                    action()
                }
                .buttonStyle(RelationshipButtonStyle(self, isLarge: true, isOpaque: isOpaque))
            }
        }
    }
}
