import Combine
import Foundation

extension Mastodon.API.Lists {
    static func listsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain) .appendingPathComponent("lists")
    }
    
    static func listsEndpointURL(domain: String, id: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain) .appendingPathComponent("lists/\(id)")
    }
    
    static func listAccountsEndpointURL(domain: String, id: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain) .appendingPathComponent("lists/\(id)/accounts")
    }
    
    public static func getLists(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.List]>, Error> {
        let request = Mastodon.API.get(
            url: listsEndpointURL(domain: domain),
            authorization: authorization
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.List].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func getList(
        session: URLSession,
        domain: String,
        id: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.List>, Error> {
        let request = Mastodon.API.get(
            url: listAccountsEndpointURL(domain: domain, id: id),
            authorization: authorization
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.List.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
