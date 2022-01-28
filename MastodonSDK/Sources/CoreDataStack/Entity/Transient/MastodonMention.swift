//
//  MastodonMention.swift
//  CoreDataStack
//
//  Created by MainasuK on 2022-1-17.
//

import Foundation

public final class MastodonMention: NSObject, Codable {

    public typealias ID = String
    
    public let id: ID
    public let username: String
    public let acct: String
    public let url: String
    
    public init(
        id: MastodonMention.ID,
        username: String,
        acct: String,
        url: String
    ) {
        self.id = id
        self.username = username
        self.acct = acct
        self.url = url
    }
    
}
