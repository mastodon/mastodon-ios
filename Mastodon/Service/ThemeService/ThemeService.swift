//
//  ThemeService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import Combine
import AppShared

// ref: https://zamzam.io/protocol-oriented-themes-for-ios-apps/
final class ThemeService {
    
    static let tintColor: UIColor = .label

    // MARK: - Singleton
    public static let shared = ThemeService()

    let currentTheme: CurrentValueSubject<Theme, Never>

    private init() {
        let theme = ThemeName(rawValue: UserDefaults.shared.currentThemeNameRawValue)?.theme ?? ThemeName.mastodon.theme
        currentTheme = CurrentValueSubject(theme)
    }

}
