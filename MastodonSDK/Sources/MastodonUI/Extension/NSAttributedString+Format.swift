// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public extension NSAttributedString {
    convenience init(format: NSAttributedString, args: NSAttributedString...) {
        let mutableNSAttributedString = NSMutableAttributedString(attributedString: format)

        zip(format.string.ranges(of: "%@"), Array(args)).forEach { range, arg in
            mutableNSAttributedString.replaceCharacters(in: .init(range: range, originalText: format.string), with: arg)
        }

        self.init(attributedString: mutableNSAttributedString)
    }
}

private extension String {
    func ranges(of searchString: String) -> [Range<String.Index>] {
        let indices = indices(of: searchString)
        let count = searchString.count
        return indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
    }
    
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex, to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex, to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound, offsetBy: offset, limitedBy: endIndex) else {
                break
            }
            position = index(after: after)
        }
        return indices
    }
}

private extension NSRange {
    init(range: Range<String.Index>, originalText: String) {
        self.init(
            location: range.lowerBound.utf16Offset(in: originalText),
            length: range.upperBound.utf16Offset(in: originalText) - range.lowerBound.utf16Offset(in: originalText)
        )
    }
}
