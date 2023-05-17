//
//  Mastodon+Entity+Attachment.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Attachment
    ///
    /// - Since: 0.6.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/attachment/)
    public struct Attachment: Codable, Sendable {
        
        public typealias ID = String
        
        public let id: ID
        public let type: Type
        public let url: String?           // media v2 may return null url
        public let previewURL: String?    // could be nil when attachment is audio
        
        public let remoteURL: String?
        public let textURL: String?
        public let meta: Meta?
        public let description: String?
        public let blurhash: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case url
            case previewURL = "preview_url"
            
            case remoteURL = "remote_url"
            case textURL = "text_url"
            case meta
            case description
            case blurhash
        }
    }
}

extension Mastodon.Entity.Attachment {
    public typealias AttachmentType = Type
    public enum `Type`: RawRepresentable, Codable, Sendable {
        case unknown
        case image
        case gifv
        case video
        case audio
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "unknown":     self = .unknown
            case "image":       self = .image
            case "gifv":        self = .gifv
            case "video":       self = .video
            case "audio":       self = .audio
            default:            self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .unknown:              return "unknown"
            case .image:                return "image"
            case .gifv:                 return "gifv"
            case .video:                return "video"
            case .audio:                return "audio"
            case ._other(let value):    return value
            }
        }
    }
}


extension Mastodon.Entity.Attachment {
    /// # Reference
    ///   https://github.com/tootsuite/mastodon/blob/v3.3.0/app/models/media_attachment.rb
    public struct Meta: Codable, Sendable {
        public let original: Format?
        public let small: Format?
        public let focus: Focus?
        
        public let length: String?
        public let duration: Double?
        public let fps: Int?
        public let size: String?
        public let width: Int?
        public let height: Int?
        public let aspect: Double?
        public let audioEncode: String?
        public let audioBitrate: String?
        public let audioChannels: String?
        
        enum CodingKeys: String, CodingKey {
            case original
            case small
            case focus
            
            case length
            case duration
            case fps
            case size
            case width
            case height
            case aspect
            case audioEncode = "audio_encode"
            case audioBitrate = "audio_bitrate"
            case audioChannels = "audio_channels"
        }
        
    }
}

extension Mastodon.Entity.Attachment.Meta {
    public struct Format: Codable, Sendable {
        public let width: Int?
        public let height: Int?
        public let size: String?
        public let aspect: Double?
        public let frameRate: String?
        public let duration: Double?
        public let bitrate: Int?
        
        enum CodingKeys: String, CodingKey {
            case width
            case height
            case size
            case aspect
            case frameRate = "frame_rate"
            case duration
            case bitrate
        }
    }
    
    public struct Focus: Codable, Sendable {
        public let x: Double
        public let y: Double
    }
}
