//
//  APIService+LinkMentionsTimeline.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 6/25/26.
//

import Foundation
import MastodonSDK

@MainActor extension APIService {
    public func linkMentionsTimeline(
        linkUrl: String,
        sinceID: Mastodon.Entity.Status.ID? = nil,
        maxID: Mastodon.Entity.Status.ID? = nil,
        limit: Int = onceRequestStatusMaxCount,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let query = Mastodon.API.Timeline.LinkMentionsTimelineQuery(
            url: linkUrl,
            maxID: maxID,
            sinceID: sinceID,
            minID: nil,
            limit: limit
        )
        return try await Mastodon.API.Timeline.linkMentions(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        )
    }
}
