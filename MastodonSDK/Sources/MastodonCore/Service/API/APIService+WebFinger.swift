//
//  APIService+WebFinger.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-8.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {

    private static func webFingerEndpointURL(domain: String) -> URL {
        
        return URL(string: "\(URL.httpScheme(domain: domain))://\(domain)/")!
            .appendingPathComponent(".well-known")
            .appendingPathComponent("webfinger")
    }

    public func webFinger(
        domain: String
    ) -> AnyPublisher<String, Error> {
        let url = APIService.webFingerEndpointURL(domain: domain)
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 3)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                return response.url?.host ?? domain
            }
            .eraseToAnyPublisher()
    }

}
