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

    // inspired by https://stackoverflow.com/a/49072718
    public func isValidURL() -> Bool {
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: absoluteString, options: [], range: NSRange(location: 0, length: absoluteString.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == absoluteString.utf16.count
        } else {
            return false
        }
    }
}
