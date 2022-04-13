//
//  ThemeService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import Combine
import AppShared
import MastodonCommon

// ref: https://zamzam.io/protocol-oriented-themes-for-ios-apps/
public final class ThemeService {
    
    public static let tintColor: UIColor = .label

    // MARK: - Singleton
    public static let shared = ThemeService()

    public let currentTheme: CurrentValueSubject<Theme, Never>

    private init() {
        let theme = ThemeName(rawValue: UserDefaults.shared.currentThemeNameRawValue)?.theme ?? ThemeName.mastodon.theme
        currentTheme = CurrentValueSubject(theme)
    }

}

extension ThemeName {
    public var theme: Theme {
        switch self {
        case .system:       return SystemTheme()
        case .mastodon:     return MastodonTheme()
        }
    }
}
