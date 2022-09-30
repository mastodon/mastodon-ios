//
//  APIService+Filter.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-9.
//

import os.log
import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension APIService {

    func filters(
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Filter]>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let domain = mastodonAuthenticationBox.domain

        return Mastodon.API.Account.filters(session: session, domain: domain, authorization: authorization)
    }
}
