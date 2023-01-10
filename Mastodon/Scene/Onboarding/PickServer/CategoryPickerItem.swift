//
//  CategoryPickerItem.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import Foundation
import MastodonSDK
import MastodonAsset
import MastodonLocalization

/// Note: update Equatable when change case
enum CategoryPickerItem {
    case language(language: String?)
    case signupSpeed(manuallyReviewed: Bool?)
    case category(category: Mastodon.Entity.Category)
}

extension CategoryPickerItem {
    
    var title: String {
        switch self {
        case .language(let language):
            if let language {
                return language
            } else {
                return L10n.Scene.ServerPicker.Button.language
            }
        case .signupSpeed(let manuallyReviewed):
            if let manuallyReviewed {
                if manuallyReviewed {
                    return L10n.Scene.ServerPicker.SignupSpeed.manuallyReviewed
                } else {
                    return L10n.Scene.ServerPicker.SignupSpeed.instant
                }
            } else {
                return L10n.Scene.ServerPicker.Button.signupSpeed
            }
        case .category(let category):
            switch category.category {
            case .academia:
                return L10n.Scene.ServerPicker.Button.Category.academia
            case .activism:
                return L10n.Scene.ServerPicker.Button.Category.activism
            case .food:
                return L10n.Scene.ServerPicker.Button.Category.food
            case .furry:
                return L10n.Scene.ServerPicker.Button.Category.furry
            case .games:
                return L10n.Scene.ServerPicker.Button.Category.games
            case .general:
                return L10n.Scene.ServerPicker.Button.Category.general
            case .journalism:
                return L10n.Scene.ServerPicker.Button.Category.journalism
            case .lgbt:
                return L10n.Scene.ServerPicker.Button.Category.lgbt
            case .regional:
                return L10n.Scene.ServerPicker.Button.Category.regional
            case .art:
                return L10n.Scene.ServerPicker.Button.Category.art
            case .music:
                return L10n.Scene.ServerPicker.Button.Category.music
            case .tech:
                return L10n.Scene.ServerPicker.Button.Category.tech
            case ._other:
                return "-"  // FIXME:
            }
        }
    }
    
    var accessibilityDescription: String {
        switch self {
        case .language(let language):
            if let language {
                return language
            } else {
                return L10n.Scene.ServerPicker.Button.language
            }
        case .signupSpeed(let manuallyReviewed):
            if let manuallyReviewed {
                if manuallyReviewed {
                    return L10n.Scene.ServerPicker.SignupSpeed.manuallyReviewed
                } else {
                    return L10n.Scene.ServerPicker.SignupSpeed.instant
                }
            } else {
                return L10n.Scene.ServerPicker.Button.signupSpeed
            }
        case .category(let category):
            switch category.category {
            case .academia:
                return L10n.Scene.ServerPicker.Button.Category.academia
            case .activism:
                return L10n.Scene.ServerPicker.Button.Category.activism
            case .food:
                return L10n.Scene.ServerPicker.Button.Category.food
            case .furry:
                return L10n.Scene.ServerPicker.Button.Category.furry
            case .games:
                return L10n.Scene.ServerPicker.Button.Category.games
            case .general:
                return L10n.Scene.ServerPicker.Button.Category.general
            case .journalism:
                return L10n.Scene.ServerPicker.Button.Category.journalism
            case .lgbt:
                return L10n.Scene.ServerPicker.Button.Category.lgbt
            case .regional:
                return L10n.Scene.ServerPicker.Button.Category.regional
            case .art:
                return L10n.Scene.ServerPicker.Button.Category.art
            case .music:
                return L10n.Scene.ServerPicker.Button.Category.music
            case .tech:
                return L10n.Scene.ServerPicker.Button.Category.tech
            case ._other:
                return "-"  // FIXME:
            }
        }
    }
}

extension CategoryPickerItem: Equatable {
    static func == (lhs: CategoryPickerItem, rhs: CategoryPickerItem) -> Bool {
        switch (lhs, rhs) {
        case (.category(let categoryLeft), .category(let categoryRight)):
            return categoryLeft.category.rawValue == categoryRight.category.rawValue
        case (.language(let languageLeft), .language(let languageRight)):
            return languageLeft == languageRight
        case (.signupSpeed(let leftManualReview), .signupSpeed(let rightManualReview)):
            return leftManualReview == rightManualReview
        default:
            return false
        }
    }
}

extension CategoryPickerItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .language(let language):
            if let language {
                return hasher.combine(language)
            } else {
                return hasher.combine("no_language_selected")
            }
        case .category(let category):
            hasher.combine(category.category.rawValue)
        case .signupSpeed(let manuallyReviewed):
            if let manuallyReviewed {
                return hasher.combine(manuallyReviewed)
            } else {
                return hasher.combine("no_signup_speed_selected")
            }
        }
    }
}
