//
//  MastodonRegex.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-14.
//

import Foundation

public enum MastodonRegex {
    /// mention,  hashtag.
    /// @...
    /// #...
    public static let highlightPattern = "(?:@([a-zA-Z0-9_]+)(@[a-zA-Z0-9_.-]+)?|#([^\\s.]+))"
    /// emoji
    /// :shortcode:
    /// accept ^\B: or \s: but not accept \B: to force user input a space to make emoji take effect
    /// precondition :\B with following space
    public static let emojiPattern = "(?:(^\\B:|\\s:)([a-zA-Z0-9_]+)(:\\B(?=\\s)))"
    /// mention, hashtag, emoji
    /// @…
    /// #…
    /// :…
    public static let autoCompletePattern = "(?:@([a-zA-Z0-9_]+)(@[a-zA-Z0-9_.-]+)?|#([^\\s.]+))|(^\\B:|\\s:)([a-zA-Z0-9_]+)"
}
