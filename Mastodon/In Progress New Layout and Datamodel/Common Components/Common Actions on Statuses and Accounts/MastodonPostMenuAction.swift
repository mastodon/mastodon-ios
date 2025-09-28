// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization
import MastodonSDK

public func languageName(_ identifier: String?) -> String? {
    guard let identifier else { return nil }
    return Locale.current.localizedString(forIdentifier: identifier)
}

enum PostActionFailure: Error {
    case translationEmptyOrInvalid
    case noTargetAccountInfo
    case noActionablePostId
    case noRelationshipInfo
    case postIdMismatch
    case unsupportedAction
}

@MainActor
protocol MastodonPostMenuActionHandler {
    func account(_ id: Mastodon.Entity.Account.ID) -> MastodonAccount?
    func doAction(_ action: MastodonPostMenuAction, forPost postViewModel: MastodonPostViewModel)
    func commitCurrentQuotePolicyEdit() async throws
    func doAction(_ action: MastodonPostMenuAction, forAccount account: MastodonAccount) async throws
    func canTranslate(post: MastodonContentPost) -> Bool
    func translation(forContentPostId postId: Mastodon.Entity.Status.ID) -> Mastodon.Entity.Translation?
    func presentScene(_ scene: SceneCoordinator.Scene, fromPost postID: Mastodon.Entity.Status.ID?, transition: SceneCoordinator.Transition)
    func showOverlay(_ modalView: MastodonTimelineOverlayView?)
    func showSheet(_ sheet: MastodonTimelineSheet?)
    func vote(poll: Mastodon.Entity.Poll, choices: [Int], containingPostID: Mastodon.Entity.Status.ID) async throws -> Mastodon.Entity.Poll
    var mediaPreviewableViewController: MediaPreviewableViewController? { get }
    func currentRelationship(to account: Mastodon.Entity.Account.ID) -> MastodonAccount.Relationship?
}


enum MastodonPostMenuAction: String {
    
    enum SubmenuType: String {
        case edit
        case translate
        case postActions
        case relationshipActions
        case defensiveActions
        case delete
    }
    
    struct Submenu: Identifiable {
        let id: MastodonPostMenuAction.SubmenuType
        let items: [MastodonPostMenuAction]
        
        init?(_ id: MastodonPostMenuAction.SubmenuType, items: [MastodonPostMenuAction]?) {
            guard let items, !items.isEmpty else { return nil }
            self.id = id
            self.items = items
        }
    }
    
    // ACTION BAR ITEMS
    case reply
    case boost
    case unboost
    case favourite
    case unfavourite
    case bookmark
    case unbookmark
    
    // EDIT
    case editPost
    case changeQuotePolicy
    
    // TRANSLATE
    case translatePost
    case showOriginalLanguage
    
    // POST ACTIONS
    case sharePost
    case openPostInBrowser
    case copyLinkToPost

    // RELATIONSHIP ACTIONS
    case follow
    case unfollow
    case mute
    case unmute
    
    // DEFENSIVE ACTIONS
    case removeQuote
    case blockUser
    case unblockUser
    case reportUser
    
    // DELETE
    case deletePost
    
    var updatesMyRelationshipToAuthor: Bool {
        switch self {
        case .reply:
            false
            
        case .boost, .unboost, .favourite, .unfavourite, .bookmark, .unbookmark:
            false
            
        case .editPost, .changeQuotePolicy:
            false
            
        case .translatePost, .showOriginalLanguage:
            false
            
        case .follow, .unfollow, .mute, .unmute:
            true
            
        case .sharePost, .openPostInBrowser, .copyLinkToPost:
            false
            
        case .removeQuote:
            false
            
        case .blockUser, .unblockUser:
            true
            
        case .reportUser:
            false
            
        case .deletePost:
            false
        }
    }
    
    var updatesMyActionsOnPost: Bool {
        switch self {
        case .reply:
            false
            
        case .boost, .unboost, .favourite, .unfavourite, .bookmark, .unbookmark:
            true
            
        case .editPost, .changeQuotePolicy:
            true
            
        case .translatePost, .showOriginalLanguage:
            false
            
        case .follow, .unfollow, .mute, .unmute:
            false
            
        case .sharePost, .openPostInBrowser, .copyLinkToPost:
            false
            
        case .blockUser, .unblockUser:
            false
            
        case .reportUser:
            false
            
        case .deletePost, .removeQuote:
            true
        }
    }
    
    var iconSystemName: String {
        switch self {
        case .reply:
            PostAction.reply.systemIconName(filled: false)
        case .boost:
            PostAction.boost.systemIconName(filled: false)
        case .unboost:
            PostAction.boost.systemIconName(filled: true)
        case .favourite:
            PostAction.favourite.systemIconName(filled: false)
        case .unfavourite:
            PostAction.favourite.systemIconName(filled: true)
        case .bookmark:
            PostAction.bookmark.systemIconName(filled: false)
        case .unbookmark:
            PostAction.bookmark.systemIconName(filled: true)
        case .translatePost, .showOriginalLanguage:
            "character.book.closed"
        case .reportUser:
            "flag"
        case .follow:
            "person.badge.plus"
        case .unfollow:
            "person.badge.minus"
        case .mute:
            "speaker.slash"
        case .unmute:
            "speaker.wave.2"
        case .removeQuote:
            "exclamationmark.bubble"
        case .blockUser:
            "hand.raised.slash"
        case .unblockUser:
            "hand.raised"
        case .sharePost:
            "square.and.arrow.up"
        case .deletePost:
            "minus.circle"
        case .editPost:
            "pencil"
        case .changeQuotePolicy:
            "quote.opening"
        case .copyLinkToPost:
            "doc.on.doc"
        case .openPostInBrowser:
            "safari"
        }
    }
    
    func labelText(username: String?, postLanguage: String?) -> String {
        let username = username ?? ""
        let postLanguage = postLanguage ?? ""
        switch self {
        case .reply:
            return L10n.Common.Controls.Actions.reply
        case .boost:
            return L10n.Common.Controls.Status.Actions.reblog
        case .unboost:
            return L10n.Common.Controls.Status.Actions.unreblog
        case .favourite:
            return L10n.Common.Controls.Status.Actions.favorite
        case .unfavourite:
            return L10n.Common.Controls.Status.Actions.unfavorite
        case .bookmark:
            return L10n.Common.Controls.Actions.bookmark
        case .unbookmark:
            return L10n.Common.Controls.Actions.removeBookmark
        case .translatePost:
            let language = languageName(postLanguage) ?? L10n.Common.Controls.Actions.TranslatePost.unknownLanguage
            return L10n.Common.Controls.Actions.TranslatePost.title(language)
        case .showOriginalLanguage:
            return L10n.Common.Controls.Status.Translation.showOriginal
        case .reportUser:
            return L10n.Common.Controls.Actions.reportUser(username)
        case .follow:
            return L10n.Common.Controls.Actions.follow(username)
        case .unfollow:
            return L10n.Common.Controls.Actions.unfollow(username)
        case .mute:
            return L10n.Common.Controls.Friendship.muteUser(username)
        case .unmute:
            return L10n.Common.Controls.Friendship.unmuteUser(username)
        case .removeQuote:
            return L10n.Common.Controls.Actions.removeQuote
        case .blockUser:
            return L10n.Common.Controls.Friendship.blockUser(username)
        case .unblockUser:
            return L10n.Common.Controls.Friendship.unblockUser(username)
        case .sharePost:
            return L10n.Common.Controls.Actions.sharePost
        case .deletePost:
            return L10n.Common.Controls.Actions.delete
        case .editPost:
            return L10n.Common.Controls.Actions.editPost
        case .changeQuotePolicy:
            return L10n.Common.Controls.Actions.changeQuotePolicy
        case .copyLinkToPost:
            return L10n.Common.Controls.Status.Actions.copyLink
        case .openPostInBrowser:
            return L10n.Common.Controls.Actions.openInBrowser
        }
    }
    
    var isDestructive: Bool {
        switch self {
        case .blockUser, .reportUser, .deletePost, .removeQuote:
            return true
        default:
            return false
        }
    }
    
    static func menuItems(forPostBy relationship: MastodonAccount.Relationship, isQuotingMe: Bool, isShowingTranslation: Bool?) -> [MastodonPostMenuAction.Submenu] {
        
        let editActions: [MastodonPostMenuAction]? =  {
            switch relationship {
            case .isMe:
                [ MastodonPostMenuAction.editPost, .changeQuotePolicy ]
            case .isNotMe:
                nil
            }
        }()
        
        let translateAction: [MastodonPostMenuAction]? =  {
            guard let isShowingTranslation else { return nil }
            return  [isShowingTranslation ? .showOriginalLanguage : .translatePost]
        }()
        
        let postActions = [MastodonPostMenuAction.sharePost, .copyLinkToPost, .openPostInBrowser]
        
        let relationshipActions: [MastodonPostMenuAction]?
        let defensiveActions: [MastodonPostMenuAction]?
        
        switch relationship {
        case .isMe:
            relationshipActions = nil
            defensiveActions = isQuotingMe ? [ .removeQuote ] : nil
        case .isNotMe(let info):
            if let info {
                relationshipActions = [
                    (info.iFollowThem || info.iHaveRequestedToFollowThem) ? .unfollow : .follow,
                    info.iAmMutingThem ? .unmute : .mute
                ]
                defensiveActions = [
                    isQuotingMe ? .removeQuote : nil,
                    info.iAmBlockingThem ? .unblockUser : .blockUser,
                    .reportUser
                ].compactMap { $0 }
            } else {
                relationshipActions = nil
                defensiveActions = nil
            }
        }
        
        let deleteAction: [MastodonPostMenuAction]? = {
            switch relationship {
            case .isMe:
                [.deletePost]
            case .isNotMe:
                nil
            }
        }()
        
        let submenus: [MastodonPostMenuAction.Submenu] = [
            .init(.edit, items: editActions),
            .init(.translate, items: translateAction),
            .init(.postActions, items: postActions),
            .init(.relationshipActions, items: relationshipActions),
            .init(.defensiveActions, items: defensiveActions),
            .init(.delete, items: deleteAction)
        ].compactMap { $0 }
        return submenus
    }
    
    static func authorA11yMenuItems(forPostBy relationship: MastodonAccount.Relationship, isQuotingMe: Bool, isShowingTranslation: Bool?) -> [MastodonPostMenuAction] {
        
        let relationshipActions: [MastodonPostMenuAction]
        let defensiveActions: [MastodonPostMenuAction]
        
        switch relationship {
        case .isMe:
            relationshipActions = []
            defensiveActions = isQuotingMe ? [ .removeQuote ] : []
        case .isNotMe(let info):
            if let info {
                relationshipActions = [
                    (info.iFollowThem || info.iHaveRequestedToFollowThem) ? .unfollow : .follow,
                    info.iAmMutingThem ? .unmute : .mute
                ]
                defensiveActions = [
                    isQuotingMe ? .removeQuote : nil,
                    info.iAmBlockingThem ? .unblockUser : .blockUser,
                    .reportUser
                ].compactMap { $0 }
            } else {
                relationshipActions = []
                defensiveActions = []
            }
        }
        
        return relationshipActions + defensiveActions
    }
    
    static func postA11yMenuItemsOtherThanReply(forPostBy relationship: MastodonAccount.Relationship, myActions: MastodonContentPost.PostActions?, isShowingTranslation: Bool?) -> [MastodonPostMenuAction] {
        
        let actionBarActions: [MastodonPostMenuAction] = [myActions?.boosted == true ? .unboost : .boost, myActions?.favorited == true ? .unfavourite : .favourite, myActions?.bookmarked == true ? .bookmark : .unbookmark]
        
        let editActions: [MastodonPostMenuAction] =  {
            switch relationship {
            case .isMe:
                [ MastodonPostMenuAction.editPost, .changeQuotePolicy ]
            case .isNotMe:
                []
            }
        }()
        
        let deleteAction: [MastodonPostMenuAction] = {
            switch relationship {
            case .isMe:
                [.deletePost]
            case .isNotMe:
                []
            }
        }()
        
        let translateAction: [MastodonPostMenuAction] =  {
            guard let isShowingTranslation else { return [] }
            return  [isShowingTranslation ? .showOriginalLanguage : .translatePost]
        }()
        
        let postActions = [MastodonPostMenuAction.sharePost, .copyLinkToPost, .openPostInBrowser]
        
        let actions: [MastodonPostMenuAction] =
            (actionBarActions +
            editActions +
            deleteAction +
            translateAction +
            postActions).compactMap { $0 }
        return actions
    }
}

extension MastodonPostMenuAction: Identifiable {
    var id: String { rawValue }
}
