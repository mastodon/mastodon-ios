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
 
    func uploadMedia(
        domain: String,
        query: Mastodon.API.Media.UploadMeidaQuery,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Media.uploadMedia(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
    
}
