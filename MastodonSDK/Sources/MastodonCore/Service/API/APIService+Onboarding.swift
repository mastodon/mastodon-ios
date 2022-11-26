//
//  APIService+Onboarding.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-19.
//

import Foundation
import Combine
import MastodonSDK

extension APIService {
 
    public func servers(
        language: String? = nil,
        category: String? = nil
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Server]>, Error> {
        let query = Mastodon.API.Onboarding.ServersQuery(language: language, category: category)
        return Mastodon.API.Onboarding.servers(session: session, query: query)
    }
    
    public func categories() -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Category]>, Error> {
        return Mastodon.API.Onboarding.categories(session: session)
    }
    
    public static func stubCategories() -> [Mastodon.Entity.Category] {
        return Mastodon.Entity.Category.Kind.allCases.map { kind in
            return Mastodon.Entity.Category(category: kind.rawValue, serversCount: 0)
        }
    }
    
}
