// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Foundation

extension Character {
    var isEmoji: Bool {
        // for why this isn't as simple as you'd think, see https://developer.apple.com/documentation/swift/unicode/scalar/properties-swift.struct/isemoji
        unicodeScalars.contains { $0.properties.isEmojiPresentation }
        || (
            unicodeScalars.contains { $0.properties.isEmoji }
            && unicodeScalars.contains{ $0.value == 0xFE0F }
        )
    }
}

let emojiFirstComparator: (String, String) -> ComparisonResult = { a, b in
    let aChars = Array(a)
    let bChars = Array(b)
    
    let count = min(aChars.count, bChars.count)
    
    for i in 0..<count {
        let lhs = aChars[i]
        let rhs = bChars[i]
        
        if lhs == rhs { continue }
        
        let lhsEmoji = lhs.isEmoji
        let rhsEmoji = rhs.isEmoji
        
        if lhsEmoji != rhsEmoji {
            // prioritize emoji characters in the sort
            if lhsEmoji && !rhsEmoji {
                return .orderedAscending
            } else {
                return .orderedDescending
            }
        }
        
        // Fallback to regular comparison if characters are both or neither emoji
        return String(lhs).localizedStandardCompare(String(rhs))
    }
    
    // If one string is a prefix of the other, the shorter string comes first
    if aChars.count == bChars.count {
        return .orderedSame
    } else if aChars.count < bChars.count {
        return .orderedAscending
    } else {
        return .orderedDescending
    }
}

