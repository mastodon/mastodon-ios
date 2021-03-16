//
//  CategoryPickerItem.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import Foundation
import MastodonSDK

enum CategoryPickerItem {
    case all
    case category(category: Mastodon.Entity.Category)
}

extension CategoryPickerItem {
    var title: String {
        switch self {
        case .all:
            return L10n.Scene.ServerPicker.Button.Category.all
        case .category(let category):
            switch category.category {
            case .academia:
                return "📚"
            case .activism:
                return "✊"
            case .food:
                return "🍕"
            case .furry:
                return "🦁"
            case .games:
                return "🕹"
            case .general:
                return "💬"
            case .journalism:
                return "📰"
            case .lgbt:
                return "🏳️‍🌈"
            case .regional:
                return "📍"
            case .art:
                return "🎨"
            case .music:
                return "🎼"
            case .tech:
                return "📱"
            case ._other:
                return "❓"
            }
        }
    }
}

extension CategoryPickerItem: Equatable {
    static func == (lhs: CategoryPickerItem, rhs: CategoryPickerItem) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all):
            return true
        case (.category(let categoryLeft), .category(let categoryRight)):
            return categoryLeft.category.rawValue == categoryRight.category.rawValue
        default:
            return false
        }
    }
}

extension CategoryPickerItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine(String(describing: CategoryPickerItem.all.self))
        case .category(let category):
            hasher.combine(category.category.rawValue)
        }
    }
}
