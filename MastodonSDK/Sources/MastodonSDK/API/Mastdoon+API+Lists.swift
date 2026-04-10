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
    
    public static func createList(
        listName: String,
        replyPolicy: Mastodon.Entity.ReplyPolicy,
        removeFromHome: Bool,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.List>, Error> {
        let request = Mastodon.API.post(
            url: listsEndpointURL(domain: domain),
            query: CreateListQuery(listName: listName, replyPolicy: replyPolicy, removeFromHome: removeFromHome),
            authorization: authorization
        )
       
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.List.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    struct CreateListQuery: PostQuery {
        let listName: String
        let replyPolicy: Mastodon.Entity.ReplyPolicy
        let removeFromHome: Bool
        
        var contentType: String? {
            "application/json"
        }
        
        var body: Data? {
            do {
                let dict: [String : Any] = [
                    "title" : listName,
                    "replies_policy" : replyPolicy.rawValue,
                    "exclusive" : removeFromHome
                ]
                return try JSONSerialization.data(withJSONObject: dict)
            } catch {
                assertionFailure("Error creating create list query body: \(error)")
                return nil
            }
        }
    }
    
    public static func addAccountToList(
        listId: String,
        accountID: String,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Void, Error> {
        var request = Mastodon.API.post(url: listAccountsEndpointURL(domain: domain, id: listId), query: AddToListQuery(accountID: accountID), authorization: authorization)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try Mastodon.API.decodeEmpty(from: data, response: response)
                return
            }
            .eraseToAnyPublisher()
    }
    
    public static func deleteAccountFromList(
        listId: String,
        accountID: String,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Void, Error> {
        let url = listAccountsEndpointURL(domain: domain, id: listId)
        var request = Mastodon.API.delete(url: url, query: DeleteFromListQuery(accountID: accountID), authorization: authorization)
        request.httpMethod = "DELETE"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try Mastodon.API.decodeEmpty(from: data, response: response)
                return
            }
            .eraseToAnyPublisher()
    }
    
    struct AddToListQuery: PostQuery {
        let accountID: String
        
        var contentType: String? {
            "application/json"
        }
        
        var body: Data? {
            do {
                let dict = [ "account_ids" : [accountID] ]
                return try JSONSerialization.data(withJSONObject: dict)
            } catch {
                assertionFailure("Error creating add to list query body: \(error)")
                return nil
            }
        }
    }
    
    struct DeleteFromListQuery: DeleteQuery {
        let accountID: String
        
        var contentType: String? {
            "application/json"
        }
        
        var body: Data? {
            do {
                let dict = [ "account_ids" : [accountID] ]
                return try JSONSerialization.data(withJSONObject: dict)
            } catch {
                assertionFailure("Error creating delete from list query body: \(error)")
                return nil
            }
        }
    }
}
