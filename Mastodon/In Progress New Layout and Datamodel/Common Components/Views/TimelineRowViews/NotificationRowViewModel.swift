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
    var actionHandler: MastodonPostMenuActionHandler? {
        didSet {
            relationshipViewModel.actionHandler = actionHandler
        }
    }
    let primaryNavigation: NotificationNavigation?
    
    private let relationshipViewModel = RelationshipViewModel()
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
                avatarRowAdditionalElement = .noneNeeded
            }
        case .mention, .status, .quote:
            avatarRowAdditionalElement = .noneNeeded
            break
        case .reblog(let status), .favourite(let status), .poll(let status), .update(let status), .quotedUpdate(let status):
            avatarRowAdditionalElement = .noneNeeded
            if let status {
                let inlinePost = GenericMastodonPost.fromStatus(status)
                inlinePostViewModel = MastodonPostViewModel(inlinePost.initialDisplayInfo(inContext: .notifications), filterContext: .notifications, threadedConversationContext: nil)
                inlinePostViewModel?.initialSetFullPost(inlinePost)
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
                inlinePostViewModel?.initialSetFullPost(inlinePost)
            }
        default:
            break
        }
        self.notification = MastodonNotificationInfo(newInfo)
    }
    
    private var _primaryAuthorAccountIsLocked: Bool = false
    public var needsRelationshipTo: Mastodon.Entity.Account? {
        guard let primaryAuthorAccount = avatarRowSourceAccounts?.primaryAuthorAccount else { return nil }
        switch avatarRowAdditionalElement {
        case .unfetched:
            avatarRowAdditionalElement = .fetching(notification.type)
        default:
            break
        }
        _primaryAuthorAccountIsLocked = primaryAuthorAccount.locked
        return primaryAuthorAccount
    }
    
    public func prepareForDisplay(relationship: MastodonAccount.Relationship, theirAccountIsLocked: Bool) {
        relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: theirAccountIsLocked)
        updateAvatarRowAdditionalElement()
    }
    
    private func updateAvatarRowAdditionalElement() {
        switch avatarRowAdditionalElement {
        case .noneNeeded:
            break
        case .unfetched(let groupedNotificationType), .fetching(let groupedNotificationType):
            switch groupedNotificationType {
            case .followRequest:
                avatarRowAdditionalElement = .followRequestControls(.theyHaveRequestedToFollowMe(iFollowThem: relationshipViewModel.relationship?.info?.iFollowThem ?? false))
            case .follow:
                avatarRowAdditionalElement = .relationshipButton(relationshipViewModel.button)
            default:
                avatarRowAdditionalElement = .noneNeeded
            }
        case .relationshipButton:
            avatarRowAdditionalElement = .relationshipButton(relationshipViewModel.button)
        case .followRequestControls:
            break
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
            guard let account = info.fullAccount, let relationship = relationshipViewModel.relationship?.info?._legacyEntity else { return }
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
        case .fetching, .noneNeeded, .unfetched:
            return []
        case .followRequestControls(let controls):
            switch controls {
            case .theyHaveRequestedToFollowMe:
                return [true, false].map { option in
                    A11yActionInfo(title: controls.a11yActionTitle(forAccept: option) ?? "", doAction: { [weak self] in self?.doAvatarRowButtonAction(option) })
                }
            case .iHaveAnsweredTheirRequestToFollowMe:
                return []
            }
        case .relationshipButton(let button):
            if let actionTitle = button.a11yActionTitle {
                return [ A11yActionInfo(title: actionTitle , doAction: { [weak self] in self?.doAvatarRowButtonAction() }) ]
            } else {
                return []
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
        switch avatarRowAdditionalElement {
        case .followRequestControls(let controls):
            switch controls {
            case .theyHaveRequestedToFollowMe:
                if let avatarRowSourceAccounts {
                    FeedbackGenerator.shared.generate(.selectionChanged)
                    Task {
                        await doAnswerFollowRequest(avatarRowSourceAccounts, accept: accept)
                    }
                }
            case .iHaveAnsweredTheirRequestToFollowMe:
                break
            }
        case .relationshipButton(let button):
            if let firstAccount = avatarRowSourceAccounts?.primaryAuthorAccount {
                FeedbackGenerator.shared.generate(.selectionChanged)
                Task {
                    try await relationshipViewModel.doRelationshipAction(button.buttonAction, account: MastodonAccount.fromEntity(firstAccount))
                    updateAvatarRowAdditionalElement()
                }
            }
        case .fetching, .noneNeeded, .unfetched:
            break
        }
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
        avatarRowAdditionalElement = .fetching(notification.type)
        do {
            let expectedFollowedByResult = accept
            let newRelationship = try await APIService.shared.followRequest(
                userID: accountID,
                query: accept ? .accept : .reject,
                authenticationBox: authBox
            ).value
            assert(newRelationship.followedBy == expectedFollowedByResult, "expected to update following relationship after answering follow request")
            self.avatarRowAdditionalElement = .followRequestControls(.iHaveAnsweredTheirRequestToFollowMe(didAccept: accept))
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

extension NotificationRowViewModel: FeedCoordinatorUpdatable {
    func incorporateUpdate(_ update: UpdatedElement) {
        
        inlinePostViewModel?.incorporateUpdate(update)
        
        switch update {
        case .hashtag, .deletedPost, .post:
            break
        case .relationship(let updated):
            if relationshipViewModel.relationship?.refersToSameAccount(as: updated) == true {
                relationshipViewModel.prepareForDisplay(relationship: updated, theirAccountIsLocked: _primaryAuthorAccountIsLocked)
                updateAvatarRowAdditionalElement()
            }
        }
    }
}
