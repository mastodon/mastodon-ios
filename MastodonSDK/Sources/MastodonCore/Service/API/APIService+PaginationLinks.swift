//
//  APIService+PaginationLinks.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/17/25.
//

import Foundation
import Combine
import MastodonSDK

extension APIService {
    
    public func statuses(
        fromUrl url: URL,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let response = try await Mastodon.API.Timeline.statuses(
            session: session,
            url: url,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }
    
    public func hashtags(
        fromUrl url: URL,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Tag]> {
        let response = try await Mastodon.API.Timeline.hashtags(
            session: session,
            url: url,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
    public func ungroupedNotifications(
        fromUrl url: URL,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Notification]> {
        let response = try await Mastodon.API.Timeline.ungroupedNotifications(
            session: session,
            url: url,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
    public func groupedNotifications(
        fromUrl url: URL,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.GroupedNotificationsResults> {
        let response = try await Mastodon.API.Timeline.groupedNotifications(
            session: session,
            url: url,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
}
