// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Combine

extension Mastodon.API.Statuses {
    private static func historyEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("statuses")
            .appendingPathComponent(statusID)
            .appendingPathComponent("history")
    }

    public static func editHistory(
        forStatusID statusID: Mastodon.Entity.Status.ID,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.StatusEdit]>, Error> {

        let url = historyEndpointURL(domain: domain, statusID: statusID)
        let request = Mastodon.API.get(url: url, authorization: authorization)

        return session.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.StatusEdit].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
