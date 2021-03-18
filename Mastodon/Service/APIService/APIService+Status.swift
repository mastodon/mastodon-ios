//
//  APIService+Status.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import MastodonSDK

extension APIService {
 
    func publishStatus(
        domain: String,
        query: Mastodon.API.Statuses.PublishStatusQuery,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Statuses.publishStatus(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
    
}
