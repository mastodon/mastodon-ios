//
//  MastodonRegex.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-14.
//

import Foundation

enum MastodonRegex {
    /// mention,  hashtag.
    /// @...
    /// #...
    static let highlightPattern = "(?:@([a-zA-Z0-9_]+)(@[a-zA-Z0-9_.-]+)?|#([^\\s.]+))"
    /// emoji
    /// :shortcode:
    /// accept ^\B: or \s: but not accept \B: to force user input a space to make emoji take effect
    /// precondition :\B with following space
    static let emojiPattern = "(?:(^\\B:|\\s:)([a-zA-Z0-9_]+)(:\\B(?=\\s)))"
}
