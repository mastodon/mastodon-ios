//
//  APIService+Lists.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 8/13/26.
//

import Foundation
import Combine
import MastodonSDK

extension Notification.Name {
    public static let listsDidChange = Notification.Name(rawValue: "org.joinmastodon.app.lists-changed")
}

extension APIService {
    public func createList(
        authenticationBox: MastodonAuthenticationBox,
        listName: String,
        repliesPolicy: Mastodon.Entity.ReplyPolicy,
        removeFromHomeFeed: Bool
    ) async throws -> Mastodon.Entity.List {
        
        let response = try await Mastodon.API.Lists.createList(
            listName: listName,
            replyPolicy: repliesPolicy,
            removeFromHome: removeFromHomeFeed,
            session: .shared,
            domain: authenticationBox.domain,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        NotificationCenter.default.post(name: .listsDidChange, object: nil)
        
        return response.value
    }
}
