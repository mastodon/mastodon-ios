//
//  MastodonTagHistory.swift
//  CoreDataStack
//
//  Created by MainasuK on 2022-1-20.
//

import Foundation

public final class MastodonTagHistory: NSObject, Codable {
    
    /// UNIX timestamp on midnight of the given day
    public let day: Date
    public let uses: String
    public let accounts: String
    
    public init(day: Date, uses: String, accounts: String) {
        self.day = day
        self.uses = uses
        self.accounts = accounts
    }
    
}

