//
//  APIService+Media.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import Foundation
import Combine
import MastodonSDK

extension APIService {

    public func uploadMedia(
        domain: String,
        query: Mastodon.API.Media.UploadMediaQuery,
        mastodonAuthenticationBox: MastodonAuthenticationBox,
        needsFallback: Bool
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error> {
        if needsFallback {
            return uploadMediaV1(domain: domain, query: query, mastodonAuthenticationBox: mastodonAuthenticationBox)
        } else {
            return uploadMediaV2(domain: domain, query: query, mastodonAuthenticationBox: mastodonAuthenticationBox)
        }
    }
 
    private func uploadMediaV1(
        domain: String,
        query: Mastodon.API.Media.UploadMediaQuery,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Media.uploadMedia(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
    }

    private func uploadMediaV2(
        domain: String,
        query: Mastodon.API.Media.UploadMediaQuery,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.V2.Media.uploadMedia(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
        .eraseToAnyPublisher()
    }

}

extension APIService {

    public func getMedia(
        attachmentID: Mastodon.Entity.Attachment.ID,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Media.getMedia(
            session: session,
            domain: mastodonAuthenticationBox.domain,
            attachmentID: attachmentID,
            authorization: authorization
        )
        .eraseToAnyPublisher()
    }
    
}

extension APIService {
    
    public func updateMedia(
        domain: String,
        attachmentID: Mastodon.Entity.Attachment.ID,
        query: Mastodon.API.Media.UpdateMediaQuery,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Media.updateMedia(
            session: session,
            domain: domain,
            attachmentID: attachmentID,
            query: query,
            authorization: authorization
        )
    }
    
}
