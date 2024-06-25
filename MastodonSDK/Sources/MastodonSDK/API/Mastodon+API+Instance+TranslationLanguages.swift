// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Combine

extension Mastodon.API.Instance {
    
    static func translationLanguagesEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("instance/translation_languages")
    }
    
    public static func translationLanguages(
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization?,
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<TranslationLanguages>, Error>  {
        let request = Mastodon.API.get(url: translationLanguagesEndpointURL(domain: domain), authorization: authorization)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: TranslationLanguages.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
