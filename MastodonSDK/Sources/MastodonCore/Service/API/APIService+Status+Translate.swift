//
//  APIService+Status+Translate.swift
//  Mastodon
//
//  Created by Marcus Kida on 02.12.2022.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {

    public func translateStatus(
        statusID: Mastodon.Entity.Status.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Translation> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Statuses.translate(
            session: session,
            domain: domain,
            statusID: statusID,
            authorization: authorization
        ).singleOutput()
        
        return response
    }

}
