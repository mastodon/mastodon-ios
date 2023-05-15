//
//  CustomEmojiPickerSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import Foundation

public enum CustomEmojiPickerSection: Equatable, Hashable {
    case uncategorized
    case emoji(name: String)
}
