//
//  APIService+Notification.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Combine
import Foundation
import MastodonSDK

extension APIService {
    
    public enum MastodonNotificationScope: String, Hashable, CaseIterable {
        case everything
        case mentions
    }

    public func notifications(
        olderThan maxID: Mastodon.Entity.Status.ID?,
        fromAccount accountID: String? = nil,
        scope: MastodonNotificationScope?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Notification]> {
        let authorization = authenticationBox.userAuthorization

        let types: [Mastodon.Entity.NotificationType]?
        let excludedTypes: [Mastodon.Entity.NotificationType]?

        switch scope {
        case .everything:
            types = [.follow, .followRequest, .mention, .reblog, .favourite, .poll, .status, .moderationWarning]
            excludedTypes = nil
        case .mentions:
            types = [.mention]
            excludedTypes = [.follow, .followRequest, .reblog, .favourite, .poll]
        case nil:
            types = nil
            excludedTypes = nil
        }

        let query = Mastodon.API.Notifications.Query(
            maxID: maxID,
            types: types,
            excludeTypes: excludedTypes,
            supportedTypes: Mastodon.Entity.NotificationType.supportedTypes,
            accountID: accountID
        )
        
        let response = try await Mastodon.API.Notifications.getNotifications(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        return response
    }
    
    public func groupedNotifications(
        olderThan maxID: Mastodon.Entity.Notification.ID?,
        newerThan minID: Mastodon.Entity.Notification.ID?,
        fromAccount accountID: String? = nil,
        scope: MastodonNotificationScope?,
        excludingAdminTypes: [Mastodon.Entity.NotificationType]?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.GroupedNotificationsResults> {
        let authorization = authenticationBox.userAuthorization
        
        let types: [Mastodon.Entity.NotificationType]?
        let excludedTypes: [Mastodon.Entity.NotificationType]?
        
        switch scope {
        case .everything:
            types = nil
            excludedTypes = excludingAdminTypes
        case .mentions:
            types = [.mention]
            excludedTypes = nil
        case nil:
            types = nil
            excludedTypes = nil
        }
        
        let query = Mastodon.API.Notifications.GroupedQuery(
            maxID: maxID,
            minID: minID,
            types: types,
            excludeTypes: excludedTypes,
            supportedTypes: Mastodon.Entity.NotificationType.supportedTypes,
            accountID: accountID
        )
        
        let response = try await Mastodon.API.Notifications.getGroupedNotifications(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authorization)
        
        return response
    }
}

extension APIService {
    
    public func notification(
        notificationID: Mastodon.Entity.Notification.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Notification> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Notifications.getNotification(
            session: session,
            domain: domain,
            notificationID: notificationID,
            authorization: authorization
        ).singleOutput()
        
        return response
    }

}

//MARK: - Notification Policy

extension APIService {
    public func notificationPolicy(authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<Mastodon.Entity.NotificationPolicy> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Notifications.getNotificationPolicy(session: session, domain: domain, authorization: authorization)

        return response
    }

    public func updateNotificationPolicy(
        authenticationBox: MastodonAuthenticationBox,
        forNotFollowing: Mastodon.Entity.NotificationPolicy.NotificationFilterAction,
        forNotFollowers: Mastodon.Entity.NotificationPolicy.NotificationFilterAction,
        forNewAccounts: Mastodon.Entity.NotificationPolicy.NotificationFilterAction,
        forPrivateMentions: Mastodon.Entity.NotificationPolicy.NotificationFilterAction,
        forLimitedAccounts: Mastodon.Entity.NotificationPolicy.NotificationFilterAction
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.NotificationPolicy> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        let query = Mastodon.API.Notifications.UpdateNotificationPolicyQuery(forNotFollowing: forNotFollowing, forNotFollowers: forNotFollowers, forNewAccounts: forNewAccounts, forPrivateMentions: forPrivateMentions, forLimitedAccounts: forLimitedAccounts)

        let response = try await Mastodon.API.Notifications.updateNotificationPolicy(
            session: session,
            domain: domain,
            authorization: authorization,
            query: query
        )

        return response
    }
}

//MARK: - Notification Requests

extension APIService {
    public func notificationRequests(authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<[Mastodon.Entity.NotificationRequest]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Notifications.getNotificationRequests(session: session, domain: domain, authorization: authorization)

        return response
    }

    public func acceptNotificationRequest(authenticationBox: MastodonAuthenticationBox, id: String) async throws -> Mastodon.Response.Content<[String: String]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Notifications.acceptNotificationRequest(id: id, session: session, domain: domain, authorization: authorization)
        return response
    }

    public func dismissNotificationRequest(authenticationBox: MastodonAuthenticationBox, id: String) async throws -> Mastodon.Response.Content<[String: String]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Notifications.dismissNotificationRequest(id: id, session: session, domain: domain, authorization: authorization)
        return response
    }
}
