//
//  Mastodon+API+Instance.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Foundation
import Combine

extension Mastodon.API.Instance {

    static func instanceEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("instance")
    }
    
    /// Information about the server
    ///
    /// - Since: 1.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/5
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    /// - Returns: `AnyPublisher` contains `Instance` nested in the response
    public static func instance(
        session: URLSession,
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Instance>, Error>  {
        let request = Mastodon.API.get(
            url: instanceEndpointURL(domain: domain),
            query: nil,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value: Mastodon.Entity.Instance

                do {
                    value = try Mastodon.API.decode(type: Mastodon.Entity.Instance.self, from: data, response: response)
                } catch {
                    if let response = response as? HTTPURLResponse, 400 ..< 500 ~= response.statusCode {
                        // For example, AUTHORIZED_FETCH may result in authentication errors
                        value = Mastodon.Entity.Instance(domain: domain)
                    } else {
                        throw error
                    }
                }
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
