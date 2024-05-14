import Foundation
import Combine

extension Mastodon.API.V2.Instance {

    private static func instanceEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("instance")
    }
    
    /// Information about the server
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.0
    /// # Last Update
    ///   2022/12/09
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    /// - Returns: `AnyPublisher` contains `Instance` nested in the response
    public static func instance(
        session: URLSession,
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.V2.Instance>, Error>  {
        let request = Mastodon.API.get(
            url: instanceEndpointURL(domain: domain),
            query: nil,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value: Mastodon.Entity.V2.Instance

                do {
                    value = try Mastodon.API.decode(type: Mastodon.Entity.V2.Instance.self, from: data, response: response)
                } catch {
                    if let response = response as? HTTPURLResponse, 400 ..< 500 ~= response.statusCode {
                        // For example, AUTHORIZED_FETCH may result in authentication errors
                        value = Mastodon.Entity.V2.Instance(domain: domain)
                    } else {
                        throw error
                    }
                }
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
