// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import MastodonSDK
import MastodonCore
import SwiftUI

enum MastodonMenuAction: Hashable {
    case postAction(PostMenuAction)
    case relationshipAction(RelationshipMenuAction)
    case navigationalAction(NavigationalMenuAction)
    case miscellaneous(MiscellaneousMenuAction)
    
    enum PostMenuAction: String {
        // TODO: migrate from MastodonPostMenuAction to here
        case unimplemented
    }
    
    enum RelationshipMenuAction: String {
        case follow
        case unfollow
        case hideBoosts_new
//        case unhideBoosts_new
        case mute
        case unmute
        case removeFollower_new
        case blockUser
        case unblockUser
        case reportUser
        case blockDomain_new
        case unblockDomain_new
        case personalNote_new
        
        var iconSystemName: String? {
            switch self {
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
            case .blockUser:
                "hand.raised.slash"
            case .unblockUser:
                "hand.raised"
            case .hideBoosts_new:
                nil
            case .removeFollower_new:
                nil
            case .blockDomain_new:
                nil
            case .unblockDomain_new:
                nil
            case .personalNote_new:
                nil
            }
        }
    }
    
    enum NavigationalMenuAction {
        case share([Any])
        case openInBrowser(URL)
        case myFavorites
        case myBookmarks
        case myFollowedHashtags
        case myAccountSettings
        case compose(ComposeViewModel.Context)
        case addToList_new(MastodonAccount) // account -> list
        
        var iconSystemName: String? {
            switch self {
            case .share:
                "square.and.arrow.up"
            case .openInBrowser:
                "safari"
            case .myFavorites:
                "star"
            case .myBookmarks:
                "bookmark"
            case .myFollowedHashtags:
                "number"
            case .myAccountSettings:
                "gear"
            case .compose:
                nil
            case .addToList_new:
                nil
            }
        }
    }
    
    enum MiscellaneousMenuAction: String {
        case copyLink
        case featureOnMyProfile_new  // accounts and hashtags
        case stopFeaturingOnMyProfile_new
        
        var iconSystemName: String? {
            switch self {
            case .copyLink:
                "link"
            case .featureOnMyProfile_new:
                nil
            case .stopFeaturingOnMyProfile_new:
                nil
            }
        }
        
        var labelText: String {
            switch self {
            case .copyLink:
                "Copy link"
            case .featureOnMyProfile_new:
                "FEATURE ON MY PROFILE"
            case .stopFeaturingOnMyProfile_new:
                "STOP FEATURING ON MY PROFILE"
            }
        }
    }
    
    @ViewBuilder static public func menuButton(systemImageName: String?, text: String, action: @escaping ()->()) -> some View {
        Button {
            action()
        } label: {
            Text(text)
            if let systemImageName {
                Image(systemName: systemImageName)
            }
        }
    }
}

extension MastodonMenuAction {
    @MainActor
    protocol MiscellaneousMenuActionHandler {
        func handleAction(_ action: MastodonMenuAction.MiscellaneousMenuAction)
    }
}

extension MastodonMenuAction.NavigationalMenuAction: Equatable, Hashable {
    static func == (lhs: MastodonMenuAction.NavigationalMenuAction, rhs: MastodonMenuAction.NavigationalMenuAction) -> Bool {
        switch (lhs, rhs) {
        case (share, share): true
        case (openInBrowser, openInBrowser): true
        case (myFavorites, myFavorites): true
        case (myBookmarks, myBookmarks): true
        case (myFollowedHashtags, myFollowedHashtags): true
        case (myAccountSettings, myAccountSettings): true
        case (compose(let contextL), compose(let contextR)): contextL == contextR
        default: false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .share: hasher.combine("share")
        case .openInBrowser(let url): hasher.combine("openInBrowser-\(url.absoluteString)")
        case .myFavorites: hasher.combine("myFavorites")
        case .myBookmarks: hasher.combine("myBookmarks")
        case .myFollowedHashtags: hasher.combine("myFollowedHashtags")
        case .myAccountSettings: hasher.combine("myAccountSettings")
        case .addToList_new(let account): hasher.combine("addToList-\(account.id)")
        case .compose(let context):
            switch context {
            case .mentioning(let account, let privately):
                hasher.combine("compose-\(account.acctWithDomain)-\(privately ? "private" : "public")")
            case .composeStatus(let quoting):
                if let quoting {
                    hasher.combine("compose-\(quoting.0.id)")
                } else {
                    hasher.combine("compose")
                }
            case .editStatus(let status, _, _):
                hasher.combine("compose-edit-\(status.id)")
            }
        }
    }
}

extension MastodonMenuAction {
    enum SubmenuType: String {
        case sharingActions
        case myProfileNavigations
        case accountMentionActions
        case accountFeatureAndNotes
        case mutingOptions
        case blockingOptions
    }
    
    struct Submenu: Identifiable {
        let id: MastodonMenuAction.SubmenuType
        let items: [MastodonMenuAction]
        
        init?(_ id: MastodonMenuAction.SubmenuType, items: [MastodonMenuAction]?) {
            guard let items, !items.isEmpty else { return nil }
            self.id = id
            self.items = items
        }
    }
}

extension MastodonNavigationRouter {
    @ViewBuilder func menuItem(_ menuAction: MastodonMenuAction.NavigationalMenuAction, notMyDomainName: String?) -> some View {
        if let buttonText = labelText(forAction: menuAction, domainName: notMyDomainName) {
            MastodonMenuAction.menuButton(systemImageName: menuAction.iconSystemName, text: buttonText) {
                Task {
                    do {
                        try await self.doMenuAction(menuAction)
                    } catch {
                    }
                }
            }
        }
    }
    
    func labelText(forAction menuAction: MastodonMenuAction.NavigationalMenuAction, domainName: String?) -> String? {
        switch menuAction {
        case .share:
            return "Share..."
        case .openInBrowser:
            return "Open in browser"
        case .myFavorites:
            return "Favorites"
        case .myBookmarks:
            return "Bookmarks"
        case .myFollowedHashtags:
            return "Followed hashtags"
        case .myAccountSettings:
            return "Account settings"
        case .compose(let context):
            switch context {
            case .composeStatus(let quoting):
                return quoting == nil ? "Compose" : "Quote"
            case .editStatus:
                return "Edit"
            case .mentioning(_, let privately):
                return privately ? "Privately mention" : "Mention"
            }
        case .addToList_new:
            return "Add to list..."
        }
    }
    
    func doMenuAction(_ action: MastodonMenuAction.NavigationalMenuAction) async throws {
        switch action {
        case .compose(let composeContext):
            guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
            let composeModel = ComposeViewModel(authenticationBox: authBox, composeContext: composeContext, destination: .topLevel)
            presentModal(.legacy(scene: .compose(viewModel: composeModel), transition: .modal(animated: true, completion: nil)))
            
        case .myAccountSettings:
            guard let setting = SettingService.shared.currentSetting.value else { return }
            presentModal(.legacy(scene: .settings(setting: setting), transition: .none))
        case .myBookmarks:
            push(.timeline(.myBookmarks))
        case .myFavorites:
            push(.timeline(.myFavorites))
        case .myFollowedHashtags:
            push(.timeline(.myFollowedHashtags))
        case .openInBrowser(let url):
            presentModal(.legacy(scene: .safari(url: url), transition: .safariPresent(animated: true, completion: nil)))
        case .share(let items):
            presentModal(.share(activityItems: items))
        case .addToList_new(let account):
            presentedActionSheet = .manageListMembership(account)
        }
    }
    
    private var authenticatedUser: MastodonAuthenticationBox? {
        return AuthenticationServiceProvider.shared.currentActiveUser.value
    }
    
}

extension RelationshipViewModel {
    func profileMenuActions(account: MastodonAccount, relationship: MastodonAccount.Relationship?) -> [MastodonMenuAction.Submenu] {
        guard let relationship else { return [] }
        
        let theyAreOnMyInstance = {
            switch relationship {
            case .isMe:
                return true
            case .isNotMe:
                return account.domain == AuthenticationServiceProvider.shared.currentActiveUser.value?.domain
            }
        }()
        
        var sharingActions = [
            MastodonMenuAction.miscellaneous(.copyLink)
        ]
        if let profileUrl = account.metadata.profileUrl?.absoluteString {
            sharingActions.insert(.navigationalAction(.share([profileUrl])), at: 0)
        }
    
        if let url = account.metadata.profileUrl {
            sharingActions.append(.navigationalAction(.openInBrowser(url)))
        }
        
        if relationship.isMe {
            let myNavigations = [
                MastodonMenuAction.navigationalAction(.myFavorites),
                .navigationalAction(.myBookmarks),
                .navigationalAction(.myFollowedHashtags),
                .navigationalAction(.myAccountSettings)
            ]
            return [.init(.sharingActions, items: sharingActions), .init(.myProfileNavigations, items: myNavigations)].compactMap { $0 }
        } else {
            
            let composeActions = [
                MastodonMenuAction.navigationalAction(.compose(.mentioning(account: account._legacyEntity, privately: false))),
                .navigationalAction(.compose(.mentioning(account: account._legacyEntity, privately: true)))
            ]
            
            var featureAndNotes = [MastodonMenuAction]()
            if let iFollowThem = relationship.info?.iFollowThem {
                if iFollowThem {
                    featureAndNotes.append(.navigationalAction(.addToList_new(account)))
                    if relationship.info?.iFeatureThem == false {
                        featureAndNotes.append(.miscellaneous(.featureOnMyProfile_new))
                    }
                }
                featureAndNotes.append(.relationshipAction(.personalNote_new))
            }
            
            var mutingOptions = [MastodonMenuAction]()
            if let iAmMutingThem = relationship.info?.iAmMutingThem {
                if !iAmMutingThem && relationship.info?.iFollowThem == true {
                    mutingOptions.append(.relationshipAction(.hideBoosts_new))
                }
                mutingOptions.append(iAmMutingThem ? .relationshipAction(.unmute) : .relationshipAction(.mute))
            }
            
            var blockingOptions = [MastodonMenuAction]()
            
            // REMOVE FOLLOWER
            if relationship.info?.theyFollowMe == true {
                blockingOptions.append(.relationshipAction(.removeFollower_new))
            }
            
            // BLOCK/UNBLOCK
            if let iAmBlockingThem = relationship.info?.iAmBlockingThem {
                blockingOptions.append(.relationshipAction(iAmBlockingThem ? .unblockUser : .blockUser))
            }
            
            // REPORT USER
            blockingOptions.append(.relationshipAction(.reportUser))
            
            // DOMAIN BLOCK/UNBLOCK
            if !relationship.isMe, theyAreOnMyInstance, let iAmBlockingTheirDomain = relationship.info?.iAmBlockingTheirDomain {
                blockingOptions.append(iAmBlockingTheirDomain ? .relationshipAction(.unblockDomain_new) : .relationshipAction(.blockDomain_new))
            }
            
            return [.init(.sharingActions, items: sharingActions), .init(.accountMentionActions, items: composeActions), .init(.accountFeatureAndNotes, items: featureAndNotes), .init(.mutingOptions, items: mutingOptions), .init(.blockingOptions, items: blockingOptions)].compactMap { $0 }
        }
    }
}

extension MastodonAccount.Relationship {
    var isMe: Bool {
        switch self {
        case .isMe:
            true
        case .isNotMe:
            false
        }
    }
}

extension RelationshipViewModel {
    @ViewBuilder func menuItem(_ menuAction: MastodonMenuAction.RelationshipMenuAction, forAccount account: MastodonAccount, navigator: MastodonNavigationRouter) -> some View {
        MastodonMenuAction.menuButton(systemImageName: menuAction.iconSystemName, text: labelText(forAction: menuAction, account: account)) {
            Task {
                do {
                    try await self.doMenuAction(menuAction, forAccount: account, navigator: navigator)
                } catch {
                    // TODO: real error handling
                    print("error: \(error)")
                }
            }
        }
    }
    
    func labelText(forAction menuAction: MastodonMenuAction.RelationshipMenuAction, account: MastodonAccount) -> String {
        let username = account.displayInfo.fullHandle
        let domain = account.domain
        
        switch menuAction {
        case .follow:
            return L10n.Common.Controls.Actions.follow(username)
        case .unfollow:
            return L10n.Common.Controls.Actions.unfollow(username)
        case .hideBoosts_new:
            return "HIDE BOOSTS"
            //        case .unhideBoosts_new:
            
        case .mute:
            return L10n.Common.Controls.Friendship.muteUser(username)
        case .unmute:
            return L10n.Common.Controls.Friendship.unmuteUser(username)
        case .removeFollower_new:
            return "REMOVE FOLLOWER"
        case .blockUser:
            return L10n.Common.Controls.Friendship.blockUser(username)
        case .unblockUser:
            return L10n.Common.Controls.Friendship.unblockUser(username)
        case .reportUser:
            return "REPORT USER"
            return L10n.Common.Controls.Actions.reportUser(username)
        case .blockDomain_new:
            return "BLOCK DOMAIN \(domain)"
        case .unblockDomain_new:
            return "UNBLOCK DOMAIN \(domain)"
        case .personalNote_new:
            return relationship?.info?.hasComment == true ? "EDIT PERSONAL NOTE" : "ADD PERSONAL NOTE"
        }
    }
    
    func doMenuAction(_ action: MastodonMenuAction.RelationshipMenuAction, forAccount account: MastodonAccount, navigator: MastodonNavigationRouter) async throws {
        switch action {
        case .follow:
            await commitFollow(account.id)
        case .unfollow:
            await doUnfollow(account, askFirst: UserDefaults.standard.askBeforeUnfollowingSomeone, navigator: navigator)
        case .hideBoosts_new:
            break
//        case .unhideBoosts_new:
//            break
        case .mute:
            await doMute(account, askFirst: true, navigator: navigator)
        case .unmute:
            await doUnmute(account, askFirst: true, navigator: navigator)
        case .removeFollower_new:
            break
        case .blockUser:
            await doBlock(account, navigator: navigator)
        case .unblockUser:
            await doUnblock(account, navigator: navigator)
        case .reportUser:
            break
        case .blockDomain_new:
            break
        case .unblockDomain_new:
            break
        case .personalNote_new:
            break
        }
    }
    
    private var authenticatedUser: MastodonAuthenticationBox? {
        return AuthenticationServiceProvider.shared.currentActiveUser.value
    }
    
    // MARK: Confirm Actions
    
    private func doUnfollow(_ author: MastodonAccount, askFirst: Bool, navigator: MastodonNavigationRouter) async {
        if askFirst {
            await withCheckedContinuation { continuation in
                navigator.activeAlert = .confirmUnfollow(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                    guard confirmed else { continuation.resume(); return }
                    Task {
                        await self?.doUnfollow(author, askFirst: false, navigator: navigator)
                        continuation.resume()
                    }
                })
            }
        } else {
            await commitUnfollow(author.id)
        }
    }
    
    private func doMute(_ author: MastodonAccount, askFirst: Bool, navigator: MastodonNavigationRouter) async {
        if askFirst {
            await withCheckedContinuation { continuation in
                navigator.activeAlert = .confirmMute(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                    guard confirmed else { continuation.resume(); return }
                    Task {
                        await self?.commitMute(author.id)
                        continuation.resume()
                    }
                })
            }
        } else {
            await commitMute(author.id)
        }
    }
    
    private func doUnmute(_ author: MastodonAccount, askFirst: Bool, navigator: MastodonNavigationRouter) async {
        if askFirst {
            await withCheckedContinuation { continuation in
                navigator.activeAlert = .confirmUnmute(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                    guard confirmed else { continuation.resume(); return }
                    Task {
                        await self?.commitUnmute(author.id)
                        continuation.resume()
                    }
                })
            }
        } else {
            await commitUnmute(author.id)
        }
    }
    
    private func doBlock(_ author: MastodonAccount, navigator: MastodonNavigationRouter) async {
        await withCheckedContinuation { continuation in
            navigator.activeAlert = .confirmBlock(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                guard confirmed else { continuation.resume(); return }
                Task {
                    await self?.commitBlock(author.id)
                    continuation.resume()
                }
            })
        }
    }
    
    private func doUnblock(_ author: MastodonAccount, navigator: MastodonNavigationRouter) async {
        await withCheckedContinuation { continuation in
            navigator.activeAlert = .confirmUnblock(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                guard confirmed else { continuation.resume(); return }
                Task {
                    await self?.commitUnblock(author.id)
                    continuation.resume()
                }
            })
        }
    }
    
    // MARK: Commit Actions
    
    private func commitFollow(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.follow(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitUnfollow(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unfollow(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitMute(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.mute(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitUnmute(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unmute(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    // MARK: Error handling
    private func didReceiveError(_ error: Error) {
        //TODO: something useful
        print("error received by relationship view model: \(error)")
    }
    
    private func commitBlock(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.block(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitUnblock(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unblock(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
}

//func labelText(username: String?, postLanguage: String?) -> String {
//    let username = username ?? ""
//    let postLanguage = postLanguage ?? ""
//    switch self {
//    case .reply:
//        return L10n.Common.Controls.Actions.reply
//    case .boost:
//        return L10n.Common.Controls.Status.Actions.reblog
//    case .unboost:
//        return L10n.Common.Controls.Status.Actions.unreblog
//    case .favourite:
//        return L10n.Common.Controls.Status.Actions.favorite
//    case .unfavourite:
//        return L10n.Common.Controls.Status.Actions.unfavorite
//    case .bookmark:
//        return L10n.Common.Controls.Actions.bookmark
//    case .unbookmark:
//        return L10n.Common.Controls.Actions.removeBookmark
//    case .translatePost:
//        let language = languageName(postLanguage) ?? L10n.Common.Controls.Actions.TranslatePost.unknownLanguage
//        return L10n.Common.Controls.Actions.TranslatePost.title(language)
//    case .showOriginalLanguage:
//        return L10n.Common.Controls.Status.Translation.showOriginal
//   
//    case .follow:
//        return L10n.Common.Controls.Actions.follow(username)
//    case .unfollow:
//        return L10n.Common.Controls.Actions.unfollow(username)
//    case .mute:
//        return L10n.Common.Controls.Friendship.muteUser(username)
//    case .unmute:
//        return L10n.Common.Controls.Friendship.unmuteUser(username)
//    case .removeQuote:
//        return L10n.Common.Controls.Actions.removeQuote
//    case .blockUser:
//        return L10n.Common.Controls.Friendship.blockUser(username)
//    case .unblockUser:
//        return L10n.Common.Controls.Friendship.unblockUser(username)
//    case .sharePost:
//        return L10n.Common.Controls.Actions.sharePost
//    case .copyOriginalText, .copyTranslatedText:
//        return L10n.Common.Controls.Actions.copy
//    case .deletePost:
//        return L10n.Common.Controls.Actions.delete
//    case .editPost:
//        return L10n.Common.Controls.Actions.editPost
//    case .changeQuotePolicy:
//        return L10n.Common.Controls.Actions.changeQuotePolicy
//    case .copyLinkToPost:
//        return L10n.Common.Controls.Status.Actions.copyLink
//    case .openPostInBrowser:
//        return L10n.Common.Controls.Actions.openInBrowser
//    }
//}

extension MastodonAccount.RelationshipInfo {
    var hasComment: Bool {
        guard let myOwnComment = myOwnComment else { return false }
        return !myOwnComment.isEmpty
    }
}

extension ComposeViewModel.Context: Equatable {
    static func == (lhs: ComposeViewModel.Context, rhs: ComposeViewModel.Context) -> Bool {
        switch (lhs, rhs) {
        case (composeStatus(let quotingL), composeStatus(let quotingR)):
            quotingL?.0.id == quotingR?.0.id
        case (editStatus(let statusL, _, _), editStatus(let statusR, _, _)):
            statusL.id == statusR.id
        case (mentioning(let accountL, let privatelyL), mentioning(let accountR, let privatelyR)):
            accountL.id == accountR.id && privatelyL == privatelyR
        default:
            false
        }
    }
}
