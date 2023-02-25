//
//  File.swift
//  
//
//  Created by Nathan Mattes on 19.12.22.
//

import Foundation

extension Mastodon.Entity {

    public struct Language: Codable {
        public let locale: String
        public let serversCount: Int
        public let language: String?

        enum CodingKeys: String, CodingKey {
            case locale
            case serversCount = "servers_count"
            case language
        }

        public init(locale: String, serversCount: Int, language: String?) {
            self.locale = locale
            self.serversCount = serversCount
            self.language = language
        }
    }
}
