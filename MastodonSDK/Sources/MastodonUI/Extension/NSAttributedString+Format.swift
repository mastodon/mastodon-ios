// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public extension NSAttributedString {
    convenience init(format: NSAttributedString, args: NSAttributedString...) {
        let mutableNSAttributedString = NSMutableAttributedString(attributedString: format)

        args.forEach { attributedString in
            let range = NSString(string: mutableNSAttributedString.string).range(of: "%@")
            mutableNSAttributedString.replaceCharacters(in: range, with: attributedString)
        }
        
        self.init(attributedString: mutableNSAttributedString)
    }
}
