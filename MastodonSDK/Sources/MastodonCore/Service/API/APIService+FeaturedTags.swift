//
//  APIService+FeaturedTags.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 1/7/26.
//


import Foundation
import Combine
import MastodonSDK

extension APIService {
    
    public func featuredTags(forAccount accountID: Mastodon.Entity.Account.ID?, authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.FeaturedTag]> {
        let result: Result<Mastodon.Response.Content<[Mastodon.Entity.FeaturedTag]>, Error>
        do {
            let response = try await Mastodon.API.FeaturedTags.featuredTags(
                accountID: accountID,
                domain: authenticationBox.domain,
                session: session,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
        
        let response = try result.get()
        
        return response
    }

    public func feature(
        tag: Mastodon.Entity.Tag,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.FeaturedTag> {
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.FeaturedTag>, Error>
        do {
            let response = try await Mastodon.API.FeaturedTags.feature(
                tag: tag.name,
                domain: authenticationBox.domain,
                session: session,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
                
        let response = try result.get()
        
        return response
    }
    
    public func unfeature(
        tag: Mastodon.Entity.Tag,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        try await Mastodon.API.FeaturedTags.unfeature(
            tag: tag.name,
            domain: authenticationBox.domain,
            session: session,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
    }
}
