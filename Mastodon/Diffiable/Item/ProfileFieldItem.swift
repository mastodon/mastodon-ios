//
//  ProfileFieldItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import Foundation
import Combine
import MastodonSDK

enum ProfileFieldItem {
    case field(field: FieldValue, attribute: FieldItemAttribute)
    case addEntry(attribute: AddEntryItemAttribute)
}

protocol ProfileFieldListSeparatorLineConfigurable: AnyObject {
    var isLast: Bool { get set }
}

extension ProfileFieldItem {
    var listSeparatorLineConfigurable: ProfileFieldListSeparatorLineConfigurable? {
        switch self {
        case .field(_, let attribute):
            return attribute
        case .addEntry(let attribute):
            return attribute
        }
    }
}

extension ProfileFieldItem {
    struct FieldValue: Equatable, Hashable {
        let id: UUID
        
        var name: CurrentValueSubject<String, Never>
        var value: CurrentValueSubject<String, Never>
        
        init(id: UUID = UUID(), name: String, value: String) {
            self.id = id
            self.name = CurrentValueSubject(name)
            self.value = CurrentValueSubject(value)
        }
        
        func duplicate() -> FieldValue {
            FieldValue(name: name.value, value: value.value)
        }
        
        static func == (lhs: ProfileFieldItem.FieldValue, rhs: ProfileFieldItem.FieldValue) -> Bool {
            return lhs.id == rhs.id
                && lhs.name.value == rhs.name.value
                && lhs.value.value == rhs.value.value
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension ProfileFieldItem {
    class FieldItemAttribute: Equatable, ProfileFieldListSeparatorLineConfigurable {
        let emojiDict = CurrentValueSubject<MastodonStatusContent.EmojiDict, Never>([:])
        
        var isEditing = false
        var isLast = false
        
        static func == (lhs: ProfileFieldItem.FieldItemAttribute, rhs: ProfileFieldItem.FieldItemAttribute) -> Bool {
            return lhs.isEditing == rhs.isEditing
                && lhs.isLast == rhs.isLast
        }
    }
    
    class AddEntryItemAttribute: Equatable, ProfileFieldListSeparatorLineConfigurable {
        var isLast = false
        
        static func == (lhs: ProfileFieldItem.AddEntryItemAttribute, rhs: ProfileFieldItem.AddEntryItemAttribute) -> Bool {
            return lhs.isLast == rhs.isLast
        }
    }
}

extension ProfileFieldItem: Equatable {
    static func == (lhs: ProfileFieldItem, rhs: ProfileFieldItem) -> Bool {
        switch (lhs, rhs) {
        case (.field(let fieldLeft, let attributeLeft), .field(let fieldRight, let attributeRight)):
            return fieldLeft.id == fieldRight.id
                && attributeLeft == attributeRight
        case (.addEntry(let attributeLeft), .addEntry(let attributeRight)):
            return attributeLeft == attributeRight
        default:
            return false
        }
    }
}

extension ProfileFieldItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .field(let field, _):
            hasher.combine(field.id)
        case .addEntry:
            hasher.combine(String(describing: ProfileFieldItem.addEntry.self))
        }
    }
}
