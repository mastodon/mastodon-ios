//
//  UserIdentifier.swift
//  
//
//  Created by MainasuK on 2022-5-13.
//

import Foundation
import MastodonSDK

public protocol UserIdentifier {
    var domain: String { get }
    var userID: Mastodon.Entity.Account.ID { get }
}

public struct MastodonUserIdentifier: UserIdentifier {
    public let domain: String
    public var userID: Mastodon.Entity.Account.ID
    
    
    public init(
        domain: String,
        userID: Mastodon.Entity.Account.ID
    ) {
        self.domain = domain
        self.userID = userID
    }
}
