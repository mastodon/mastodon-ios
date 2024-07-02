//
//  APIService+CustomEmojiViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {

    func customEmoji(
        domain: String,
        authenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Emoji]>, Error> {

        return Mastodon.API.CustomEmojis.customEmojis(
            session: session,
            domain: domain,
            authorization: authenticationBox.userAuthorization
        )
    }

}
