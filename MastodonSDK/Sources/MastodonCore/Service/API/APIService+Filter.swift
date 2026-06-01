//
//  APIService+Filter.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-9.
//

import Combine
import Foundation
import MastodonSDK

extension APIService {

    func filters(
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) async throws -> [Mastodon.Entity.FilterInfo] {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let domain = mastodonAuthenticationBox.domain

        return try await Mastodon.API.Account.filters(session: session, domain: domain, authorization: authorization)
    }
}
