//
//  APIService+Instance.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
    
    public func instance(
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Instance>, Error> {
        return Mastodon.API.Instance.instance(session: session, domain: domain)
    }
    
    public func instanceV2(
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.V2.Instance>, Error> {
        return Mastodon.API.V2.Instance.instance(session: session, domain: domain)
    }
}
