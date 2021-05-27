//
//  Fields.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import Foundation
import MastodonSDK

protocol FieldContinaer {
    var fieldsData: Data? { get }
}

extension FieldContinaer {
    
    static func encode(fields: [Mastodon.Entity.Field]) -> Data? {
        return try? JSONEncoder().encode(fields)
    }

    var fields: [Mastodon.Entity.Field]? {
        let decoder = JSONDecoder()
        return fieldsData.flatMap { try? decoder.decode([Mastodon.Entity.Field].self, from: $0) }
    }
    
}

