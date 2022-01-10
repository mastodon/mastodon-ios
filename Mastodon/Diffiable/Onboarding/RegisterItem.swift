//
//  RegisterItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import Foundation

enum RegisterItem: Hashable {
    case header
    case avatar
    case name
    case username
    case email
    case password
    case hint
    case reason
}
