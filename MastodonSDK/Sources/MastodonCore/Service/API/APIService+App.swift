//
//  APIService+App.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    #if DEBUG
    private static let clientName = "Skimming"
    #else
    private static let clientName = "Mastodon for iOS"
    #endif

    private static let appWebsite = "https://app.joinmastodon.org/ios"

    public func createApplication(domain: String) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Application>, Error> {
        let query = Mastodon.API.App.CreateQuery(
            clientName: APIService.clientName,
            redirectURIs: APIService.oauthCallbackURL,
            website: APIService.appWebsite
        )
        return Mastodon.API.App.create(
            session: session,
            domain: domain,
            query: query
        )
    }

}

