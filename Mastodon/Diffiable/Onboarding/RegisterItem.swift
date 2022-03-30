//
//  RegisterItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import Foundation

enum RegisterItem: Hashable {
    case header(domain: String)
    case avatar
    case name
    case username
    case email
    case password
    case hint
    case reason
}
