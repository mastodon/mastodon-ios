//
//  MastodonVisibility.swift
//  MastodonVisibility
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

public enum MastodonVisibility: RawRepresentable {
    case `public`
    case unlisted
    case `private`
    case direct
    
    case _other(String)
    
    public init?(rawValue: String) {
        switch rawValue {
        case "public":                      self = .public
        case "unlisted":                    self = .unlisted
        case "private":                     self = .private
        case "direct":                      self = .direct
        default:                            self = ._other(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .public:                       return "public"
        case .unlisted:                     return "unlisted"
        case .private:                      return "private"
        case .direct:                       return "direct"
        case ._other(let value):            return value
        }
    }
}
