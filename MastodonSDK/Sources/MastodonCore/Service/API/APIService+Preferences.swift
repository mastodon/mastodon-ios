//
//  APIService+Preferences.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-11-28.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {

    public func preferences(
        authenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Preferences>, Error> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        return Mastodon.API.Preferences.preferences(session: session, domain: domain, authorization: authorization)
    }

}
