//
//  CustomEmojiPickerItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import Foundation
import MastodonSDK

enum CustomEmojiPickerItem {
    case emoji(attribute: CustomEmojiAttribute)
}

extension CustomEmojiPickerItem: Equatable, Hashable { }

extension CustomEmojiPickerItem {
    final class CustomEmojiAttribute: Equatable, Hashable {
        let id = UUID()
        
        let emoji: Mastodon.Entity.Emoji
        
        init(emoji: Mastodon.Entity.Emoji) {
            self.emoji = emoji
        }
        
        static func == (lhs: CustomEmojiPickerItem.CustomEmojiAttribute, rhs: CustomEmojiPickerItem.CustomEmojiAttribute) -> Bool {
            return lhs.id == rhs.id &&
                lhs.emoji.shortcode == rhs.emoji.shortcode
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
