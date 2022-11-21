//
//  CustomEmojiPickerItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import Foundation
import MastodonSDK

public enum CustomEmojiPickerItem {
    case emoji(attribute: CustomEmojiAttribute)
}

extension CustomEmojiPickerItem: Equatable, Hashable { }

extension CustomEmojiPickerItem {
    public final class CustomEmojiAttribute: Equatable, Hashable {
        public let id = UUID()
        
        public let emoji: Mastodon.Entity.Emoji
        
        public init(emoji: Mastodon.Entity.Emoji) {
            self.emoji = emoji
        }
        
        public static func == (lhs: CustomEmojiPickerItem.CustomEmojiAttribute, rhs: CustomEmojiPickerItem.CustomEmojiAttribute) -> Bool {
            return lhs.id == rhs.id &&
                lhs.emoji.shortcode == rhs.emoji.shortcode
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
