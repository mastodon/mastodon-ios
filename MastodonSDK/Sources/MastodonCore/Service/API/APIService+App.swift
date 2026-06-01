//
//  APIService+App.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine
import MastodonSDK

extension APIService {
    
    #if DEBUG
    private static let clientName = "Mastodon for iOS (Development)"
    #else
    private static let clientName = "Mastodon for iOS"
    #endif

    private static let appWebsite = "https://app.joinmastodon.org/ios"
    
    public func createApplication(domain: String) async throws -> Mastodon.Entity.Application {
        let query = Mastodon.API.App.CreateQuery(
            clientName: APIService.clientName,
            redirectURIs: APIService.oauthCallbackURL,
            website: APIService.appWebsite
        )
        return try await Mastodon.API.App.create(
            session: session,
            domain: domain,
            query: query
        )
    }

}

