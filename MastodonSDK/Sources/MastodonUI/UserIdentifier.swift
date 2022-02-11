//
//  UserIdentifier.swift
//  
//
//  Created by MainasuK on 2022-1-12.
//

import Foundation
import MastodonSDK

public protocol UserIdentifier {
    var domain: String { get }
    var userID: Mastodon.Entity.Account.ID { get }
}
