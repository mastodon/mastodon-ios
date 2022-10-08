//
//  APIService+Authentication.swift
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
 
    public func userAccessToken(
        domain: String,
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        code: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> {
        let query = Mastodon.API.OAuth.AccessTokenQuery(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            code: code,
            grantType: "authorization_code"
        )
        return Mastodon.API.OAuth.accessToken(
            session: session,
            domain: domain,
            query: query
        )
    }
    
    public func applicationAccessToken(
        domain: String,
        clientID: String,
        clientSecret: String,
        redirectURI: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> {
        let query = Mastodon.API.OAuth.AccessTokenQuery(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            code: nil,
            grantType: "client_credentials"
        )
        return Mastodon.API.OAuth.accessToken(
            session: session,
            domain: domain,
            query: query
        )
    }

}
