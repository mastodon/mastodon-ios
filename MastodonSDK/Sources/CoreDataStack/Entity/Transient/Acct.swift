//
//  Feed+Acct.swift
//  Feed+Acct
//
//  Created by Cirno MainasuK on 2021-8-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

extension Feed {
    public enum Acct: RawRepresentable {
        case none
        case mastodon(domain: String, userID: String)
        
        public init?(rawValue: String) {
            let components = rawValue.split(separator: "@", maxSplits: 2)
            guard components.count == 3 else { return nil }
            let userID = String(components[1]).escape
            let domain = String(components[2]).escape
            
            switch components[0] {
            case "M":
                self = .mastodon(domain: domain, userID: userID)
            default:
                self = .none
            }
            
        }
        
        public var rawValue: String {
            switch self {
            case .none:
                return "none@userID@domain"
            case .mastodon(let domain, let userID):
                return "M@\(userID.escape)@\(domain.escape)"
            }
        }
    }
}

extension String {
    fileprivate var escape: String {
        replacingOccurrences(of: "@", with: "_at_")
    }
}
