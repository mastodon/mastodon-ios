//
//  APIService+Instance.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Foundation
import Combine
import MastodonSDK

extension APIService {
    
    public func instance(
        domain: String,
        authenticationBox: MastodonAuthenticationBox?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Instance>, Error> {
        return Mastodon.API.Instance.instance(session: session, authorization: authenticationBox?.userAuthorization, domain: domain)
    }
    
    public func instance(
        domain: String,
        authenticationBox: MastodonAuthenticationBox?
    ) async throws -> Mastodon.Entity.Instance {
        return try await Mastodon.API.Instance.instance(session: session, authorization: authenticationBox?.userAuthorization, domain: domain)
    }
    
    public func instanceV2(
        domain: String,
        authenticationBox: MastodonAuthenticationBox?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.V2.Instance>, Error> {
        return Mastodon.API.V2.Instance.instance(session: session, authorization: authenticationBox?.userAuthorization, domain: domain)
    }
    public func instanceV2(
        domain: String,
        authenticationBox: MastodonAuthenticationBox?
    ) async throws -> Mastodon.Entity.V2.Instance {
        return try await Mastodon.API.V2.Instance.instance(session: session, authorization: authenticationBox?.userAuthorization, domain: domain)
    }

    public func extendedDescription(
        domain: String,
        authenticationBox: MastodonAuthenticationBox?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.ExtendedDescription>, Error> {
        return Mastodon.API.Instance.extendedDescription(session: session, authorization: authenticationBox?.userAuthorization, domain: domain)
    }
    
    public func translationLanguages(
        domain: String,
        authenticationBox: MastodonAuthenticationBox?
    ) -> AnyPublisher<Mastodon.Response.Content<TranslationLanguages>, Error> {
        return Mastodon.API.Instance.translationLanguages(session: session, authorization: authenticationBox?.userAuthorization, domain: domain)
    }
}
