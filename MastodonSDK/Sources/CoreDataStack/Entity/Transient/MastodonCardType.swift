//
//  MastodonCardType.swift
//  CoreDataStack
//
//  Created by Kyle Bashour on 11/23/22.
//

import Foundation

public enum MastodonCardType: RawRepresentable, Equatable {
    case link
    case photo
    case video

    case _other(String)

    public init(rawValue: String) {
        switch rawValue {
        case "link":    self = .link
        case "photo":   self = .photo
        case "video":   self = .video
        default:        self = ._other(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .link:                 return "link"
        case .photo:                return "photo"
        case .video:                return "video"
        case ._other(let value):    return value
        }
    }
}
