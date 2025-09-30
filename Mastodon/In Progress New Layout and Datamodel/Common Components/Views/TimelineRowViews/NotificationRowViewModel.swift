// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import SwiftUI
import UIKit

nonisolated struct MastodonNotificationInfo {
    let identifier: MastodonFeedItemIdentifier
    let timestamp: Date?
    let oldestID: String?
    let newestID: String?
    let type: GroupedNotificationType
    let author: AccountInfo?
    let sourceAccounts: NotificationSourceAccounts
    
    init(_ info: GroupedNotificationInfo) {
        self.identifier = .notificationGroup(id: info.id)
        self.timestamp = info.timestamp
        self.oldestID = info.oldestNotificationID
        self.newestID = info.newestNotificationID
        self.type = info.groupedNotificationType
        self.author = info.sourceAccounts.primaryAuthorAccount
        self.sourceAccounts = info.sourceAccounts
    }
}

@MainActor
@Observable class NotificationRowViewModel {
    var actionHandler: MastodonPostMenuActionHandler?
    let primaryNavigation: NotificationNavigation?
    
    private(set) var notification: MastodonNotificationInfo
    let myAccountDomain: String?
    let notificationID: Mastodon.Entity.Notification.ID
    
    var avatarRowSourceAccounts: NotificationSourceAccounts? {
        switch notification.type {
        case .follow, .followRequest:
            return notification.sourceAccounts
        case .reblog, .favourite, .quotedUpdate, .poll, .update, .adminSignUp:
            return notification.sourceAccounts
        case .adminReport, .moderationWarning, .severedRelationships:
            return nil
        case .mention, .status, .quote:
            // Note: these types are expected to use the MastodonPostRowView, not the NotificationRowView
            return nil
        case ._other:
            return nil
        }
    }
    var avatarRowAdditionalElement: RelationshipElement
    private var relationship: Mastodon.Entity.Relationship?
    
    enum DisplayPrepStatus {
        case unprepared
        case donePreparing
    }
    var displayPrepStatus: DisplayPrepStatus = .unprepared
    
    private var iconStyle: GroupedNotificationType.MainIconStyle? {
        return notification.type.mainIconStyle
    }
    public var iconName: String {
        switch iconStyle {
        case .icon(let name, _):
            return name
        case .avatar:
            return "person.fill.viewfinder"
        case nil:
            return "questionmark.square.dashed"
        }
    }
    public var iconColor: Color {
        switch iconStyle {
        case .icon(_, let color):
            return color
        case .avatar:
            return .secondary
        case nil:
            return .secondary
        }
    }
    
    var inlinePostViewModel: MastodonPostViewModel? = nil
    var contentConcealViewModel: ContentConcealViewModel? = nil
    var usePrivateBackground: Bool = false

    init(_ notificationInfo: GroupedNotificationInfo, myAccountDomain: String?) {
        self.primaryNavigation = notificationInfo.primaryNavigation
        self.notification = MastodonNotificationInfo(notificationInfo)
        self.myAccountDomain = myAccountDomain
        self.notificationID = notificationInfo.id
        
        switch notificationInfo.groupedNotificationType {
        case .follow, .followRequest:
            if notificationInfo.sourceAccounts
                .primaryAuthorAccount != nil
            {
                avatarRowAdditionalElement = .unfetched(
                    notificationInfo.groupedNotificationType)
            } else {
                avatarRowAdditionalElement = .error(nil)
            }
        case .mention, .status, .quote:
            avatarRowAdditionalElement = .noneNeeded
            break
        case .reblog(let status), .favourite(let status), .poll(let status), .update(let status), .quotedUpdate(let status):
            avatarRowAdditionalElement = .noneNeeded
            if let status {
                let inlinePost = GenericMastodonPost.fromStatus(status)
                inlinePostViewModel = MastodonPostViewModel(inlinePost.initialDisplayInfo(inContext: .notifications), filterContext: .notifications, threadedConversationContext: nil)
                inlinePostViewModel?.setFullPost(inlinePost)
                usePrivateBackground = status.visibility == .direct
            }
        case .adminSignUp, .adminReport, .severedRelationships, .moderationWarning:
            avatarRowAdditionalElement = .noneNeeded
        case ._other:
            avatarRowAdditionalElement = .noneNeeded
        }
    }
    
    public func update(from newInfo: GroupedNotificationInfo) {
        switch newInfo.groupedNotificationType {
        case .reblog(let status), .favourite(let status), .poll(let status), .update(let status), .quotedUpdate(let status):
            avatarRowAdditionalElement = .noneNeeded
            if let status {
                let inlinePost = GenericMastodonPost.fromStatus(status)
                inlinePostViewModel = MastodonPostViewModel(inlinePost.initialDisplayInfo(inContext: .notifications), filterContext: .notifications, threadedConversationContext: nil)
                inlinePostViewModel?.setFullPost(inlinePost)
            }
        default:
            break
        }
        self.notification = MastodonNotificationInfo(newInfo)
    }
    
    public var needsRelationshipTo: Mastodon.Entity.Account? {
        guard avatarRowSourceAccounts?.primaryAuthorAccount != nil else { return nil }
        avatarRowAdditionalElement = .fetching
        return avatarRowSourceAccounts?.primaryAuthorAccount
    }
    
    public func prepareForDisplay(relationship: Mastodon.Entity.Relationship?, theirAccountIsLocked: Bool) {
        guard let relationship else { avatarRowAdditionalElement = .noneNeeded; return }
        self.relationship = relationship
        switch avatarRowAdditionalElement {
        case .noneNeeded:
            return
        default:
            switch (notification.type, relationship.following) {
            case (.follow, true):
                avatarRowAdditionalElement = .iFollowThem(theyFollowMe: true)
            case (.follow, false):
                avatarRowAdditionalElement = .iDoNotFollowThem(
                    theirAccountIsLocked: theirAccountIsLocked)
            case (.followRequest, _):
                avatarRowAdditionalElement = .theyHaveRequestedToFollowMe(
                    iFollowThem: relationship.following)
            default:
                avatarRowAdditionalElement = .noneNeeded
            }
        }
    }
    
}

extension NotificationRowViewModel: Identifiable {
    nonisolated var id: String {
        return notificationID
    }
}

struct A11yActionInfo: Identifiable {
    let id = UUID()
    let title: String
    let doAction: ()->()
}

extension NotificationRowViewModel {
    
    func navigateToProfile(_ info: AccountInfo) async throws {
        guard
            let me = AuthenticationServiceProvider.shared
                .currentActiveUser.value?.cachedAccount
        else { return }
        if me.id == info.id {
            actionHandler?.presentScene(.profile(.me(me)), fromPost: nil, transition: .show)
        } else {
            guard let account = info.fullAccount, let relationship else { return }
            actionHandler?.presentScene(
                .profile(
                    .notMe(
                        me: me, displayAccount: account,
                        relationship: relationship)),
                fromPost: nil,
                transition: .show)
        }
    }
    
    func doPrimaryNavigation() {
        guard let primaryNavigation else { return }
        switch primaryNavigation {
        case .link(_, let url):
            guard let url else { return }
            UIApplication.shared.open(url)
        case .myFollowers, .profile:
            Task {
                guard let scene = await primaryNavigation.destinationScene()
                else { return }
                actionHandler?.presentScene(scene, fromPost: nil, transition: .show)
            }
        }
    }
    
    public var a11yActions: [A11yActionInfo] {
        var actions = [A11yActionInfo]()
        if let primaryNavigationTitle = primaryNavigation?.a11yTitle { actions.append(A11yActionInfo(title: primaryNavigationTitle, doAction: { [weak self] in self?.doPrimaryNavigation() }))
        }
        // TODO: replace the below
//        for component in self.headerComponents + self.contentComponents {
//            actions.append(contentsOf: a11yActions(forComponent: component))
//        }
        return actions
    }

//    private func a11yActions(forComponent component: NotificationViewComponent?) -> [A11yActionInfo]  {
//        switch component {
//        case .none:
//            return []
//        case let .avatarRow(sourceAccounts, relationshipElement):
//            let relationshipActions = a11yActions(forRelationshipElement: relationshipElement, isGrouped: sourceAccounts.totalActorCount > 1)
//            let accountNavigations = sourceAccounts.accounts.compactMap { account in
//                A11yActionInfo(title: L10n.Common.Controls.Status.MetaEntity.mention(account.displayName(whenViewedBy: nil)?.plainString ?? ""), doAction: {
//                    Task { [weak self] in
//                        try await self?.navigateToProfile(account)
//                    }
//                })
//            }
//            return relationshipActions + accountNavigations
//        case let .status(statusViewModel):
//            return [A11yActionInfo(title: L10n.Common.Controls.Status.showPost, doAction: { statusViewModel.navigateToStatus() })]
//        case .hyperlink(_, _):
//            return []
//        case .text, .textAndTimeLabel, .timeSinceLabel, .weightedText, ._other:
//            return []
//        }
//    }
    
    private func a11yActions(forRelationshipElement relationshipElement: RelationshipElement, isGrouped: Bool) -> [A11yActionInfo] {
        
        guard !isGrouped else { return [] }
        
        switch relationshipElement {
        case .error, .fetching, .relationshipIsChanging, .iHaveAnsweredTheirRequestToFollowMe, .noneNeeded, .unfetched(_):
            return []
        case .iDoNotFollowThem, .iFollowThem, .iHaveRequestedToFollowThem:
            return [ A11yActionInfo(title: relationshipElement.a11yActionTitle() ?? "", doAction: { [weak self] in self?.doAvatarRowButtonAction() }) ]
        case .theyHaveRequestedToFollowMe:
            return [true, false].map { option in
                A11yActionInfo(title: relationshipElement.a11yActionTitle(forAccept: option) ?? "", doAction: { [weak self] in self?.doAvatarRowButtonAction(option) })
            }
        }
    }
}

extension NotificationRowViewModel: Equatable {
    nonisolated public static func == (
        lhs: NotificationRowViewModel, rhs: NotificationRowViewModel
    ) -> Bool {
        return lhs.notificationID == rhs.notificationID
    }
}

extension NotificationRowViewModel {

    public func doAvatarRowButtonAction(_ accept: Bool = true) {
        FeedbackGenerator.shared.generate(.selectionChanged)
        Task {
            switch avatarRowAdditionalElement {
            case .iDoNotFollowThem, .iFollowThem,
                    .iHaveRequestedToFollowThem:
                if let avatarRowSourceAccounts {
                    await doFollowAction(
                        avatarRowAdditionalElement.followAction,
                        notificationSourceAccounts: avatarRowSourceAccounts)
                }
            case .theyHaveRequestedToFollowMe:
                if let avatarRowSourceAccounts {
                    await doAnswerFollowRequest(avatarRowSourceAccounts, accept: accept)
                }
            default:
                return
            }
        }
    }

    @MainActor
    private func doFollowAction(
        _ action: RelationshipElement.FollowAction,
        notificationSourceAccounts: NotificationSourceAccounts
    ) async {
        let startingAvatarRelationshipElement = avatarRowAdditionalElement
        avatarRowAdditionalElement = .relationshipIsChanging
        do {
            switch action {
            case .follow:
                guard let author = notificationSourceAccounts.primaryAuthorAccount else { return }
                let account = MastodonAccount.fromEntity(author)
                try await actionHandler?.doAction(.follow, forAccount: account)
            case .unfollow:
                guard let author = notificationSourceAccounts.primaryAuthorAccount else { return }
                let account = MastodonAccount.fromEntity(author)
                try await actionHandler?.doAction(.unfollow, forAccount: account)
            case .noAction:
                throw AppError.unexpected(
                    "action attempted for relationship element that has no action"
                )
            }
        } catch {
//            presentError?(error)
            avatarRowAdditionalElement = startingAvatarRelationshipElement
        }
        guard let author = notificationSourceAccounts.primaryAuthorAccount, let updatedRelationship = actionHandler?.currentRelationship(to: author.id) else { return }
        prepareForDisplay(relationship: updatedRelationship.info?._legacyEntity, theirAccountIsLocked: author.locked)
    }

    @MainActor
    private func doAnswerFollowRequest(
        _ accountInfo: NotificationSourceAccounts, accept: Bool
    ) async {
        guard let accountID = accountInfo.firstAccountID,
            let authBox = AuthenticationServiceProvider.shared.currentActiveUser
                .value
        else { return }
        let startingAvatarRowRelationshipElement = avatarRowAdditionalElement
        avatarRowAdditionalElement = .fetching
        do {
            let expectedFollowedByResult = accept
            let newRelationship = try await APIService.shared.followRequest(
                userID: accountID,
                query: accept ? .accept : .reject,
                authenticationBox: authBox
            ).value
            guard newRelationship.followedBy == expectedFollowedByResult else {
                self.avatarRowAdditionalElement = .error(nil)
                return
            }
            self.avatarRowAdditionalElement = .iHaveAnsweredTheirRequestToFollowMe(didAccept: accept)
        } catch {
//            presentError?(error)
            self.avatarRowAdditionalElement = startingAvatarRowRelationshipElement
        }
    }
}

extension NotificationRowViewModel {


    enum NotificationNavigation {
        case myFollowers
        case profile(Mastodon.Entity.Account)
        case link(String, URL?)

        func destinationScene() async -> SceneCoordinator.Scene? {
            guard
                let authBox = await AuthenticationServiceProvider.shared
                    .currentActiveUser.value,
                let myAccount = await authBox.cachedAccount
            else { return nil }
            switch self {
            case .link(_, let link):
                guard let link else { return nil }
                return .mastodonWebView(viewModel: WebViewModel(url: link))
            case .myFollowers:
                return .follower(
                    viewModel: FollowerListViewModel(
                        authenticationBox: authBox, domain: myAccount.domain,
                        userID: myAccount.id))
            case .profile(let account):
                if myAccount.id == account.id {
                    return .profile(.me(account))
                } else {
                    return .profile(
                        .notMe(
                            me: myAccount, displayAccount: account,
                            relationship: nil))
                }
            }
        }
    }

    static func defaultNavigation(
        _ notificationType: GroupedNotificationType, isGrouped: Bool,
        primaryAccount: Mastodon.Entity.Account?
    ) -> NotificationNavigation? {

        switch notificationType {
        case .favourite, .mention, .reblog, .poll, .status, .update, .quote, .quotedUpdate:
            break  // The status will go to the status. The actor, if only one, will go to their profile.
        case .follow:
            if isGrouped {
                return .myFollowers
            } else if let primaryAccount {
                return .profile(primaryAccount)
            }
        case .followRequest:
            if let primaryAccount {
                return .profile(primaryAccount)
            }
        case .adminSignUp:
            if !isGrouped, let primaryAccount {
                return .profile(primaryAccount)
            }
        case .adminReport(_, let url):
            let linkDescription = L10n.Scene.Notification.viewReport
            return .link(linkDescription, url)
        case .severedRelationships(_, let url):
            let linkDescription = L10n.Scene.Notification.learnMoreAboutServerBlocks
            return .link(linkDescription, url)
        case .moderationWarning(_, let url):
            let linkDescription =  L10n.Scene.Notification.Warning.learnMore
            return .link(linkDescription, url)
        case ._other(_):
            break
        }
        return nil
    }
}

extension GroupedNotificationType {
    init(
        _ notification: Mastodon.Entity.Notification,
        myAccountDomain: String,
        sourceAccounts: NotificationSourceAccounts,
        adminReportID: String?
    ) {
        switch notification.typeFromServer {
        case .follow:
            self = .follow(from: sourceAccounts)
        case .followRequest:
            if let account = sourceAccounts.primaryAuthorAccount {
                self = .followRequest(from: account)
            } else {
                self = ._other("Follow request from unknown account")
            }
        case .mention:
            self = .mention(notification.status)
        case .reblog:
            self = .reblog(notification.status)
        case .quote:
            self = .quote(notification.status)
        case .quotedUpdate:
            self = .quotedUpdate(notification.status)
        case .favourite:
            self = .favourite(notification.status)
        case .poll:
            self = .poll(notification.status)
        case .status:
            self = .status(notification.status)
        case .update:
            self = .update(notification.status)
        case .adminSignUp:
            self = .adminSignUp
        case .adminReport:
            let url: URL?
            if let adminReportID {
                url = adminReportUrl(forDomain: myAccountDomain, reportID: adminReportID)
            } else {
                url = nil
            }
            self = .adminReport(notification.adminReport, url)
        case .severedRelationships:
            let url = severedRelationshipsUrl(
                forDomain: myAccountDomain,
                notificationID: notification.id)
            self = .severedRelationships(
                notification.relationshipSeveranceEvent, url)
        case .moderationWarning:
            let url = moderationWarningUrl(forDomain: myAccountDomain, notificationID: notification.id)
            self = .moderationWarning(notification.accountWarning, url)
        case ._other(let string):
            self = ._other(string)
        }
    }

    init(
        _ notificationGroup: Mastodon.Entity.NotificationGroup,
        myAccountDomain: String,
        sourceAccounts: NotificationSourceAccounts,
        status: Mastodon.Entity.Status?,
        adminReportID: String?
    ) {
        switch notificationGroup.type {
        case .follow:
            self = .follow(from: sourceAccounts)
        case .followRequest:
            if let account = sourceAccounts.primaryAuthorAccount {
                self = .followRequest(from: account)
            } else {
                self = ._other("Follow request from unknown account")
            }
        case .mention:
            self = .mention(status)
        case .reblog:
            self = .reblog(status)
        case .quote:
            self = .quote(status)
        case .favourite:
            self = .favourite(status)
        case .poll:
            self = .poll(status)
        case .status:
            self = .status(status)
        case .update:
            self = .update(status)
        case .quotedUpdate:
            self = .quotedUpdate(status)
        case .adminSignUp:
            self = .adminSignUp
        case .adminReport:
            let url: URL?
            if let adminReportID {
                url = adminReportUrl(forDomain: myAccountDomain, reportID: adminReportID)
            } else {
                url = nil
            }
            self = .adminReport(notificationGroup.adminReport, url)
        case .severedRelationships:
            let url = severedRelationshipsUrl(forDomain: myAccountDomain, notificationID: String(notificationGroup.mostRecentNotificationID))
            self = .severedRelationships(
                notificationGroup.relationshipSeveranceEvent, url)
        case .moderationWarning:
            let url = moderationWarningUrl(forDomain: myAccountDomain, notificationID: String(notificationGroup.mostRecentNotificationID))
            self = .moderationWarning(notificationGroup.accountWarning, url)
        case ._other(let string):
            self = ._other(string)
        }
    }
}

extension NotificationSourceAccounts {
    var authorsDescription: String? {
        switch authorName {
        case .me, .none:
            return nil
        case .other(let name, _):
            if totalActorCount > 1 {
                let formatter = ListFormatter()
                return formatter.string(from: [name, L10n.Plural.Count.others(totalActorCount - 1)])
            } else {
                return name
            }
        }
    }
}


func moderationWarningUrl(forDomain domain: String, notificationID: String) -> URL?
{
    let trailingPathComponents = [
            "disputes",
            "strikes",
            notificationID,
        ]
  
    var url = URL(string: "https://" + domain)
    for component in trailingPathComponents {
        url?.append(component: component)
    }
    return url
}

func severedRelationshipsUrl(forDomain domain: String, notificationID: String) -> URL?
{
    let trailingPathComponents = ["severed_relationships"]
    var url = URL(string: "https://" + domain)
    for component in trailingPathComponents {
        url?.append(component: component)
    }
    return url
}

func adminReportUrl(forDomain domain: String, reportID: String) -> URL? {
    let trailingPathComponents = [
        "admin",
        "reports",
        reportID
    ]
    var url = URL(string: "https://" + domain)
    for component in trailingPathComponents {
        url?.append(component: component)
    }
    return url
}

extension Mastodon.Entity.AccountWarning.Action {
    var actionDescription: String {
        switch self {
        case .none:
            return L10n.Scene.Notification.Warning.none
        case .disable:
            return L10n.Scene.Notification.Warning.disable
        case .markStatusesAsSensitive:
            return L10n.Scene.Notification.Warning.markStatusesAsSensitive
        case .deleteStatuses:
            return L10n.Scene.Notification.Warning.deleteStatuses
        case .sensitive:
            return L10n.Scene.Notification.Warning.sensitive
        case .silence:
            return L10n.Scene.Notification.Warning.silence
        case .suspend:
            return L10n.Scene.Notification.Warning.suspend
        }
    }
}

func statusViewModel(_ status: Mastodon.Entity.Status,  myAccountID: String,
                     myAccountDomain: String,
                     navigateToScene: @escaping (
                        SceneCoordinator.Scene, SceneCoordinator.Transition
                     ) -> Void) -> Mastodon.Entity.Status.ViewModel {
                         
                         return status.viewModel(myAccountID: myAccountID, myDomain: myAccountDomain, navigateToStatus: {
                             Task {
                                 guard
                let authBox =
                    await AuthenticationServiceProvider.shared
                    .currentActiveUser.value
            else { return }
            await navigateToScene(
                .thread(
                    viewModel: ThreadViewModel(
                        authenticationBox: authBox,
                        optionalRoot: .root(
                            context: .init(
                                status: MastodonStatus(
                                    entity: status,
                                    showDespiteContentWarning:
                                        false))))), .show)
        }
    })
}

extension NotificationRowViewModel.NotificationNavigation {
    var a11yTitle: String? {
        switch self {
        case .link(let description, _):
            return description
        case .myFollowers:
            return L10n.Scene.Profile.Dashboard.myFollowers // TODO: improve string
        case .profile(let account):
            return  L10n.Common.Controls.Status.MetaEntity.mention(account.displayNameWithFallback)
        }
    }
}
