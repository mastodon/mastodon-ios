//
//  URL.swift
//  
//
//  Created by MainasuK on 2022-3-16.
//

import Foundation

extension URL {
    public static func httpScheme(domain: String) -> String {
        return domain.hasSuffix(".onion") ? "http" : "https"
    }
}
