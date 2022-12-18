//
//  ProfileFieldItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import Foundation
import Combine
import MastodonSDK
import MastodonMeta

enum ProfileFieldItem: Hashable {
    case createdAt(date: Date)
    case field(field: FieldValue)
    case editField(field: FieldValue)
    case addEntry
}

extension ProfileFieldItem {
    struct FieldValue: Equatable, Hashable {
        let id: UUID

        var name: CurrentValueSubject<String, Never>
        var value: CurrentValueSubject<String, Never>
        var verifiedAt: CurrentValueSubject<Date?, Never>
        
        let emojiMeta: MastodonContent.Emojis

        init(
            id: UUID = UUID(),
            name: String,
            value: String,
            verifiedAt: Date?,
            emojiMeta: MastodonContent.Emojis
        ) {
            self.id = id
            self.name = CurrentValueSubject(name)
            self.value = CurrentValueSubject(value)
            self.verifiedAt = CurrentValueSubject(verifiedAt)
            self.emojiMeta = emojiMeta
        }
        
        static func == (
            lhs: ProfileFieldItem.FieldValue,
            rhs: ProfileFieldItem.FieldValue
        ) -> Bool {
            return lhs.id == rhs.id
                && lhs.name.value == rhs.name.value
                && lhs.value.value == rhs.value.value
                && lhs.verifiedAt.value == rhs.verifiedAt.value
                && lhs.emojiMeta == rhs.emojiMeta
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
