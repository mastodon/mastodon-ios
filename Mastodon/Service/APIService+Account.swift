//
//  APIService+Account.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine
import MastodonSDK

extension APIService {
    
    func accountVerifyCredentials(
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        return Mastodon.API.Account.verifyCredentials(
            session: session,
            domain: domain,
            authorization: authorization
        )
    }
}
