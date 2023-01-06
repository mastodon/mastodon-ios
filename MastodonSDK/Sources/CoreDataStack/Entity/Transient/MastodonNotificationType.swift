//
//  MastodonNotificationType.swift
//  CoreDataStack
//
//  Created by MainasuK on 2022-1-21.
//

import Foundation

public enum MastodonNotificationType: RawRepresentable, Equatable {
    case follow
    case followRequest
    case mention
    case reblog
    case favourite      // same to API
    case poll
    case status
    
    case _other(String)
    
    public init?(rawValue: String) {
        switch rawValue {
        case "follow":              self = .follow
        case "follow_request":      self = .followRequest
        case "mention":             self = .mention
        case "reblog":              self = .reblog
        case "favourite":           self = .favourite
        case "poll":                self = .poll
        case "status":              self = .status
        default:                    self = ._other(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .follow:               return "follow"
        case .followRequest:        return "follow_request"
        case .mention:              return "mention"
        case .reblog:               return "reblog"
        case .favourite:            return "favourite"
        case .poll:                 return "poll"
        case .status:               return "status"
        case ._other(let value):    return value
        }
    }
}
