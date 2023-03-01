//
//  Mastodon+Entity+Category.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-18.
//

import Foundation

extension Mastodon.Entity {

    public struct Category: Codable, Sendable {
        public let category: Kind
        public let serversCount: Int

        enum CodingKeys: String, CodingKey {
            case category
            case serversCount = "servers_count"
        }
        
        public init(category: String, serversCount: Int) {
            self.category = Kind(rawValue: category) ?? ._other(category)
            self.serversCount = serversCount
        }
        
        /// # Reference
        ///   https://joinmastodon.org/communities
        public enum Kind: RawRepresentable, Codable, Sendable {
            
            case general
            case regional
            case art
            case music
            case journalism
            case activism
            case lgbt
            case games
            case tech
            case academia
            case furry
            case food
            
            case _other(String)
            
            public init?(rawValue: String) {
                switch rawValue {
                case "general":             self = .general
                case "regional":            self = .regional
                case "art":                 self = .art
                case "music":               self = .music
                case "journalism":          self = .journalism
                case "activism":            self = .activism
                case "lgbt":                self = .lgbt
                case "games":               self = .games
                case "tech":                self = .tech
                case "academia":            self = .academia
                case "furry":               self = .furry
                case "food":                self = .food
                default:                    self = ._other(rawValue)
                }
            }
            
            public var rawValue: String {
                switch self {
                case .general:                  return "general"
                case .regional:                 return "regional"
                case .art:                      return "art"
                case .music:                    return "music"
                case .journalism:               return "journalism"
                case .activism:                 return "activism"
                case .lgbt:                     return "lgbt"
                case .games:                    return "games"
                case .tech:                     return "tech"
                case .academia:                 return "academia"
                case .furry:                    return "furry"
                case .food:                     return "food"
                case ._other(let value):        return value
                }
            }
        }
    }

}

extension Mastodon.Entity.Category.Kind: CaseIterable {
    public static var allCases: [Mastodon.Entity.Category.Kind] {
        return [
            .general,
            .regional,
            .art,
            .music,
            .journalism,
            .activism,
            .lgbt,
            .games,
            .tech,
            .academia,
            .furry,
            .food,
        ]
    }
}
