//
//  APIService+Poll.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    public func poll(
        poll: Mastodon.Entity.Poll,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Polls.poll(
            session: session,
            domain: authenticationBox.domain,
            pollID: poll.id,
            authorization: authorization
        ).singleOutput()

        return response
    }
    
}

extension APIService {

    public func vote(
        poll: Mastodon.Entity.Poll,
        choices: [Int],
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {

        let response = try await Mastodon.API.Polls.vote(
            session: session,
            domain: authenticationBox.domain,
            pollID: poll.id,
            query: Mastodon.API.Polls.VoteQuery(choices: choices),
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }
    
}
