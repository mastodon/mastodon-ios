//
//  Mastodon+Entity+Category.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-18.
//

import Foundation

extension Mastodon.Entity {

    public struct Category: Codable {
        public let category: String
        public let serversCount: Int

        enum CodingKeys: String, CodingKey {
            case category
            case serversCount = "servers_count"
        }
    }

}
