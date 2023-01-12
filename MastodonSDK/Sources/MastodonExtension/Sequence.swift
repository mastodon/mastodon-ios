// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

extension Collection<AttributedString> {
    // ref: https://github.com/apple/swift/blob/700bcb4e4b97da61517c8b8831c72015207612f9/stdlib/public/core/String.swift#L727-L750
    @inlinable public func joined(separator: AttributedString = "") -> AttributedString {
        var result: AttributedString = ""
        if separator.characters.isEmpty {
            for x in self {
                result.append(x)
            }
            return result
        }
        
        var iter = makeIterator()
        if let first = iter.next() {
            result.append(first)
            while let next = iter.next() {
                result.append(separator)
                result.append(next)
            }
        }
        return result
    }
}
