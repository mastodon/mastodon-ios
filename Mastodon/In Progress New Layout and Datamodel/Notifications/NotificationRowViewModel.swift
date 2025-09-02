// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import SwiftUI
import UIKit

struct MastodonNotificationInfo {
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

class NotificationRowViewModel: ObservableObject {
    let timestampUpdater: TimestampUpdater
   
    let navigateToScene:
    (SceneCoordinator.Scene, SceneCoordinator.Transition) -> Void
    let presentError: (Error) -> Void
    let primaryNavigation: NotificationNavigation?
    
    let notification: MastodonNotificationInfo
    let iconStyle: GroupedNotificationType.MainIconStyle?
    let usePrivateBackground: Bool
    let actionSuperheader: (iconName: String?, text: String, color: Color)?
    
    @Published public var headerComponents: [NotificationViewComponent] = []
    public var contentComponents: [NotificationViewComponent] = []

    private(set) var avatarRow: NotificationViewComponent? {
        didSet {
            resetHeaderComponents()
        }
    }
    private(set) var headerTextComponents: [NotificationViewComponent] = [] {
        didSet {
            resetHeaderComponents()
        }
    }

    private func resetHeaderComponents() {
        headerComponents = ([avatarRow] + headerTextComponents).compactMap {
            $0
        }
    }

    init(
        _ notificationInfo: GroupedNotificationInfo,
        timestamper: TimestampUpdater,
        myAccountID: String,
        myAccountDomain: String,
        navigateToScene: @escaping (
            SceneCoordinator.Scene, SceneCoordinator.Transition
        ) -> Void, presentError: @escaping (Error) -> Void
    ) {
        self.timestampUpdater = timestamper
        self.iconStyle = notificationInfo.groupedNotificationType.mainIconStyle
        self.navigateToScene = navigateToScene
        self.presentError = presentError
        self.primaryNavigation = notificationInfo.primaryNavigation
        self.notification = MastodonNotificationInfo(notificationInfo)
        
        var needsPrivateBackground = false
        
        func newStatusViewModel(_ status: Mastodon.Entity.Status) -> Mastodon.Entity.Status.ViewModel {
            return statusViewModel(status, myAccountID: myAccountID, myAccountDomain: myAccountDomain, navigateToScene: navigateToScene)
        }

        switch notificationInfo.groupedNotificationType {

        case .follow, .followRequest:
            actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: false, isPrivateStatus: false)
            let avatarRowAdditionalElement: RelationshipElement
            if notificationInfo.sourceAccounts
                .primaryAuthorAccount != nil
            {
                avatarRowAdditionalElement = .unfetched(
                    notificationInfo.groupedNotificationType)
            } else {
                avatarRowAdditionalElement = .error(nil)
            }
            avatarRow = .avatarRow(
                notificationInfo.sourceAccounts,
                avatarRowAdditionalElement)
            if (notificationInfo.sourceAccounts
                .primaryAuthorAccount?
                .displayNameWithFallback) != nil
            {
                if let timestamp = notificationInfo.timestamp {
                    headerTextComponents = [
                        .textAndTimeLabel(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "", timestamp)
                    ]
                } else {
                    headerTextComponents = [
                        .text(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "")
                    ]
                }
            }
        case .mention(let status), .status(let status):
            // TODO: eventually make this full status style, not inline
            if let status
            {
                let statusViewModel = newStatusViewModel(status)
                actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: statusViewModel.isReplyToMe, isPrivateStatus: statusViewModel.visibility == .direct)
                if let timestamp = notificationInfo.timestamp {
                    headerTextComponents = [
                        .textAndTimeLabel(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "", timestamp)
                    ]
                } else {
                    headerTextComponents = [
                        .text(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "")
                    ]
                }
                contentComponents = [.status(statusViewModel)]
                needsPrivateBackground = status.visibility == .direct
            } else {
                actionSuperheader = nil
                headerTextComponents = [._other("POST BY UNKNOWN ACCOUNT")]
            }
        case .reblog(let status), .favourite(let status), .quote(let status):
            actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: false, isPrivateStatus: status?.visibility == .direct)
            if let status {
                let statusViewModel = newStatusViewModel(status)
                avatarRow = .avatarRow(
                    notificationInfo.sourceAccounts,
                    .noneNeeded)
                if let timestamp = notificationInfo.timestamp {
                    headerTextComponents = [
                        .textAndTimeLabel(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "", timestamp)
                    ]
                } else {
                    headerTextComponents = [
                        .text(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "")
                    ]
                }
                contentComponents = [.status(statusViewModel)]
                needsPrivateBackground = statusViewModel.visibility == .direct
            } else {
                headerTextComponents = [
                    ._other("REBLOGGED/FAVOURITED/QUOTED BY UNKNOWN ACCOUNT")
                ]
            }
        case .poll(let status), .update(let status), .quotedUpdate(let status):
            actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: false, isPrivateStatus: status?.visibility == .direct)
            if let status {
                let statusViewModel = newStatusViewModel(status)
                if let timestamp = notificationInfo.timestamp {
                    headerTextComponents = [
                        .textAndTimeLabel(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "", timestamp)
                    ]
                } else {
                    headerTextComponents = [
                        .text(
                            notificationInfo.groupedNotificationType
                                .actionSummaryLabel(notificationInfo.sourceAccounts)
                            ?? "")
                    ]
                }
                contentComponents = [.status(statusViewModel)]
                needsPrivateBackground = statusViewModel.visibility == .direct
            } else {
                headerTextComponents = [
                    ._other("POLL/UPDATE FROM UNKNOWN ACCOUNT")
                ]
            }
        case .adminSignUp:
            actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: false, isPrivateStatus: false)
            avatarRow = .avatarRow(
                notificationInfo.sourceAccounts,
                .noneNeeded)
            if let timestamp = notificationInfo.timestamp {
                headerTextComponents = [
                    .textAndTimeLabel(
                        notificationInfo.groupedNotificationType
                            .actionSummaryLabel(notificationInfo.sourceAccounts)
                        ?? "", timestamp)
                ]
            } else {
                headerTextComponents = [
                    .text(
                        notificationInfo.groupedNotificationType
                            .actionSummaryLabel(notificationInfo.sourceAccounts)
                        ?? "")
                ]
            }
        case .adminReport(let report, _):
            actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: false, isPrivateStatus: false)
            if let summary = report?.summary {
                if let timestamp = notificationInfo.timestamp {
                    headerTextComponents = [
                        .textAndTimeLabel(summary, timestamp)
                    ]
                } else {
                    headerTextComponents = [
                        .text(summary)
                    ]
                }
            }
            if let comment = report?
                .displayableComment
            {
                contentComponents = [.text(comment)]
            }
        case .severedRelationships(let severanceEvent, let url):
            actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: false, isPrivateStatus: false)
            if let summary = severanceEvent?.summary(myDomain: myAccountDomain)
            {
                if let timestamp = notificationInfo.timestamp {
                    headerTextComponents = [
                        .textAndTimeLabel(summary, timestamp)
                    ]
                } else {
                    headerTextComponents = [
                        .text(summary)
                    ]
                }
            } else {
                headerTextComponents = [
                    ._other(
                        "An admin action removed some of your followers or accounts that you followed."
                    )
                ]
            }
            contentComponents = [
                .hyperlink(
                    L10n.Scene.Notification.learnMoreAboutServerBlocks,
                    url)
            ]
        case .moderationWarning(let accountWarning, let url):
            actionSuperheader = NotificationRowViewModel.actionSuperheader(notificationInfo.groupedNotificationType, isReply: false, isPrivateStatus: false)
            if let timestamp = notificationInfo.timestamp {
                headerTextComponents = [
                    .textAndTimeLabel(
                        AttributedString((accountWarning?.action ?? .none).actionDescription), timestamp)
                ]
            } else {
                headerTextComponents = [
                    .weightedText(
                        (accountWarning?.action ?? .none).actionDescription,
                        .regular)
                ]
            }

            let learnMoreButton = NotificationViewComponent.hyperlink(
                L10n.Scene.Notification.Warning.learnMore, url)

            if let accountWarningText = accountWarning?.text {
                contentComponents = [
                    .weightedText(accountWarningText, .regular),
                    learnMoreButton,
                ]
            } else {
                contentComponents = [
                    learnMoreButton
                ]
            }

        case ._other(let text):
            actionSuperheader = nil
            headerTextComponents = [
                ._other("UNEXPECTED NOTIFICATION TYPE: \(text)")
            ]
        }
        
        usePrivateBackground = needsPrivateBackground
        
        resetHeaderComponents()
    }
    
    static func actionSuperheader(_ notificationType: GroupedNotificationType, isReply: Bool, isPrivateStatus: Bool?) -> (iconName: String?, text: String, color: Color)? {
        let isPrivateStatus = isPrivateStatus ?? false
        let color = isPrivateStatus ? Asset.Colors.accent.swiftUIColor : .secondary
        switch notificationType {
        case .mention:
            switch (isReply, isPrivateStatus) {
            case (true, false):
                return (iconName: PostAction.reply.systemIconName(filled: false), text: L10n.Common.Controls.Status.reply, color: color)
            case (true, true):
                return (iconName: PostAction.reply.systemIconName(filled: false), text: L10n.Common.Controls.Status.privateReply, color: color)
            case (false, false):
                return (iconName: "at", text: L10n.Common.Controls.Status.mention, color: color)
            case (false, true):
                return (iconName: "at", text: L10n.Common.Controls.Status.privateMention, color: color)
            }
        default:
            return nil
        }
    }

    public func prepareForDisplay() {
        if let avatarRow {
            switch avatarRow {
            case .avatarRow(let sourceAccounts, let additionalElement):
                switch additionalElement {
                case .unfetched:
                    fetchRelationshipElement(sourceAccounts: sourceAccounts)
                default:
                    break
                }
            case .text, .weightedText, .status, .hyperlink, ._other, .timeSinceLabel, .textAndTimeLabel:
                break
            }
        }

    }

    private func fetchRelationshipElement(
        sourceAccounts: NotificationSourceAccounts
    ) {
        switch notification.type {
        case .follow, .followRequest:
            guard let accountID = sourceAccounts.firstAccountID,
                  let accountIsLocked = sourceAccounts.primaryAuthorAccount?
                .locked
            else { return }
            avatarRow = .avatarRow(sourceAccounts, .fetching)

            Task { @MainActor in
                let element: RelationshipElement
                do {
                    if let relationship = try await fetchRelationship(
                        to: accountID)
                    {

                        switch (notification.type, relationship.following) {
                        case (.follow, true):
                            element = .iFollowThem(theyFollowMe: true)
                        case (.follow, false):
                            element = .iDoNotFollowThem(
                                theirAccountIsLocked: accountIsLocked)
                        case (.followRequest, _):
                            element = .theyHaveRequestedToFollowMe(
                                iFollowThem: relationship.following)
                        default:
                            element = .noneNeeded
                        }
                    } else {
                        element = .noneNeeded
                    }
                } catch {
                    element = .error(error)
                }

                avatarRow = .avatarRow(notification.sourceAccounts, element)
            }
        default:
            avatarRow = .avatarRow(notification.sourceAccounts, .noneNeeded)
        }
    }
    
    private func fetchAccount(_ accountID: String) async throws -> Mastodon.Entity.Account? {
        guard let authBox = await AuthenticationServiceProvider.shared.currentActiveUser.value else { return nil }
        return try await APIService.shared.accountInfo(domain: authBox.domain, userID: accountID, authorization: authBox.userAuthorization)
    }

    private func fetchRelationship(to accountID: String) async throws
    -> Mastodon.Entity.Relationship?
    {
        guard
            let authBox = await AuthenticationServiceProvider.shared
                .currentActiveUser.value
        else { return nil }
        if let relationship = try await APIService.shared.relationship(
            forAccountIds: [accountID], authenticationBox: authBox
        ).value.first {
            return relationship
        } else {
            return nil
        }
    }
}

extension NotificationRowViewModel: Identifiable {
    var id: String {
        return notification.identifier.id
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
            let me = await AuthenticationServiceProvider.shared
                .currentActiveUser.value?.cachedAccount
        else { return }
        if me.id == info.id {
            navigateToScene(.profile(.me(me)), .show)
        } else {
            var account = info.fullAccount
            if account == nil {
                account = try await fetchAccount(info.id)
            }
            guard let account else { return }
            let relationship = try await fetchRelationship(to: info.id)
            navigateToScene(
                .profile(
                    .notMe(
                        me: me, displayAccount: account,
                        relationship: relationship)), .show)
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
                navigateToScene(scene, .show)
            }
        }
    }
    
    public var a11yActions: [A11yActionInfo] {
        var actions = [A11yActionInfo]()
        if let primaryNavigationTitle = primaryNavigation?.a11yTitle { actions.append(A11yActionInfo(title: primaryNavigationTitle, doAction: { [weak self] in self?.doPrimaryNavigation() }))
        }
        for component in self.headerComponents + self.contentComponents {
            actions.append(contentsOf: a11yActions(forComponent: component))
        }
        return actions
    }

    private func a11yActions(forComponent component: NotificationViewComponent?) -> [A11yActionInfo]  {
        switch component {
        case .none:
            return []
        case let .avatarRow(sourceAccounts, relationshipElement):
            let relationshipActions = a11yActions(forRelationshipElement: relationshipElement, isGrouped: sourceAccounts.totalActorCount > 1)
            let accountNavigations = sourceAccounts.accounts.compactMap { account in
                A11yActionInfo(title: L10n.Common.Controls.Status.MetaEntity.mention(account.displayName(whenViewedBy: nil)?.plainString ?? ""), doAction: {
                    Task { [weak self] in
                        try await self?.navigateToProfile(account)
                    }
                })
            }
            return relationshipActions + accountNavigations
        case let .status(statusViewModel):
            return [A11yActionInfo(title: L10n.Common.Controls.Status.showPost, doAction: { statusViewModel.navigateToStatus() })]
        case .hyperlink(_, _):
            return []
        case .text, .textAndTimeLabel, .timeSinceLabel, .weightedText, ._other:
            return []
        }
    }
    
    private func a11yActions(forRelationshipElement relationshipElement: RelationshipElement, isGrouped: Bool) -> [A11yActionInfo] {
        
        guard !isGrouped else { return [] }
        
        switch relationshipElement {
        case .error, .fetching, .iHaveAnsweredTheirRequestToFollowMe, .noneNeeded, .unfetched(_):
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
    public static func == (
        lhs: NotificationRowViewModel, rhs: NotificationRowViewModel
    ) -> Bool {
        return lhs.notification.identifier == rhs.notification.identifier
    }
}

extension NotificationRowViewModel {

    public func doAvatarRowButtonAction(_ accept: Bool = true) {
        guard let avatarRow else { return }
        FeedbackGenerator.shared.generate(.selectionChanged)
        Task {
            switch avatarRow {
            case .avatarRow(let accountInfo, let relationshipElement):
                switch relationshipElement {
                case .iDoNotFollowThem, .iFollowThem,
                    .iHaveRequestedToFollowThem:
                    await doFollowAction(
                        relationshipElement.followAction,
                        notificationSourceAccounts: accountInfo)
                case .theyHaveRequestedToFollowMe:
                    await doAnswerFollowRequest(accountInfo, accept: accept)
                default:
                    return
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
        guard let accountID = notificationSourceAccounts.firstAccountID,
            let theirAccountIsLocked = notificationSourceAccounts
                .primaryAuthorAccount?.locked,
            let authBox = AuthenticationServiceProvider.shared.currentActiveUser
                .value
        else { return }
        let startingAvatarRow = avatarRow
        avatarRow = .avatarRow(notificationSourceAccounts, .fetching)
        do {
            let updatedElement: RelationshipElement
            let response: Mastodon.Entity.Relationship
            switch action {
            case .follow:
                response = try await APIService.shared.follow(
                    accountID, authenticationBox: authBox)
            case .unfollow:
                response = try await APIService.shared.unfollow(
                    accountID, authenticationBox: authBox)
            case .noAction:
                throw AppError.unexpected(
                    "action attempted for relationship element that has no action"
                )
            }
            if response.following {
                updatedElement = .iFollowThem(theyFollowMe: response.followedBy)
            } else if response.requested {
                updatedElement = .iHaveRequestedToFollowThem
            } else {
                updatedElement = .iDoNotFollowThem(
                    theirAccountIsLocked: theirAccountIsLocked)
            }
            avatarRow = .avatarRow(notificationSourceAccounts, updatedElement)
        } catch {
            presentError(error)
            avatarRow = startingAvatarRow
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
        let startingAvatarRow = avatarRow
        avatarRow = .avatarRow(accountInfo, .fetching)
        do {
            let expectedFollowedByResult = accept
            let newRelationship = try await APIService.shared.followRequest(
                userID: accountID,
                query: accept ? .accept : .reject,
                authenticationBox: authBox
            ).value
            guard newRelationship.followedBy == expectedFollowedByResult else {
                self.avatarRow = .avatarRow(accountInfo, .error(nil))
                return
            }
            self.avatarRow = .avatarRow(
                accountInfo,
                .iHaveAnsweredTheirRequestToFollowMe(didAccept: accept))
        } catch {
            presentError(error)
            self.avatarRow = startingAvatarRow
        }
    }
}

extension NotificationRowViewModel {
    static func viewModelsFromGroupedNotificationInfos(
        _ results: [GroupedNotificationInfo],
        timestamper: TimestampUpdater,
        myAccountID: String,
        myAccountDomain: String,
        navigateToScene: @escaping (
            SceneCoordinator.Scene, SceneCoordinator.Transition
        ) -> Void, presentError: @escaping (Error) -> Void
    ) -> [NotificationRowViewModel] {
        return results.map { info in
            NotificationRowViewModel(
                info, timestamper: timestamper, myAccountID: myAccountID, myAccountDomain: myAccountDomain,
                navigateToScene: navigateToScene,
                presentError: presentError)
        }
    }

    static func viewModelsFromUngroupedNotifications(
        _ notifications: [Mastodon.Entity.Notification],
        timestamper: TimestampUpdater,
        myAccountID: String,
        myAccountDomain: String,
        navigateToScene: @escaping (
            SceneCoordinator.Scene, SceneCoordinator.Transition
        ) -> Void, presentError: @escaping (Error) -> Void
    ) -> [NotificationRowViewModel] {

        return notifications.map { notification in
            let sourceAccounts = NotificationSourceAccounts(
                myAccountID: myAccountID,
                accounts: [notification.account], totalActorCount: 1)
            
            let status = notification.status
            
            let groupedNotificationType = GroupedNotificationType(
                notification, myAccountDomain: myAccountDomain, sourceAccounts: sourceAccounts, adminReportID: notification.adminReport?.id)
            let info = GroupedNotificationInfo(
                id: notification.id,
                timestamp: notification.createdAt,
                oldestNotificationID: notification.id,
                newestNotificationID: notification.id,
                groupedNotificationType: groupedNotificationType,
                sourceAccounts: sourceAccounts,
                status: status,
                primaryNavigation: defaultNavigation(
                    groupedNotificationType, isGrouped: false,
                                                primaryAccount: notification.primaryAuthorAccount))

            return NotificationRowViewModel(
                info, timestamper: timestamper, myAccountID: myAccountID, myAccountDomain: myAccountDomain,
                navigateToScene: navigateToScene,
                presentError: presentError)
        }
    }

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
