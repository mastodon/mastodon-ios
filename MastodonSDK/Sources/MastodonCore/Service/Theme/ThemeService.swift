//
//  ThemeService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import Combine
import MastodonCommon

// ref: https://zamzam.io/protocol-oriented-themes-for-ios-apps/
public final class ThemeService {
    
    public static let tintColor: UIColor = .label

    // MARK: - Singleton
    public static let shared = ThemeService()

    public let currentTheme: CurrentValueSubject<Theme, Never>

    private init() {
        let theme = ThemeName.system.theme
        currentTheme = CurrentValueSubject(theme)
    }

}

extension ThemeName {
    public var theme: Theme {
        switch self {
        case .system:
            return SystemTheme()
        }
    }
}

extension ThemeService {
    public func set(themeName: ThemeName) {
        UserDefaults.shared.currentThemeNameRawValue = themeName.rawValue

        let theme = themeName.theme
        apply(theme: theme)
        currentTheme.value = theme
    }

    public func apply(theme: Theme) {
        // set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        let translucentColor = theme.navigationBarBackgroundColor.withAlphaComponent(0.99)
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = translucentColor
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance

        // set tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()

        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        tabBarItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.clear]
        tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        tabBarItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.clear]
        tabBarItemAppearance.selected.iconColor = theme.tabBarItemSelectedIconColor
        tabBarItemAppearance.focused.iconColor = theme.tabBarItemFocusedIconColor
        tabBarItemAppearance.normal.iconColor = theme.tabBarItemNormalIconColor
        tabBarItemAppearance.disabled.iconColor = theme.tabBarItemDisabledIconColor
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance

        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = translucentColor
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().barTintColor = theme.tabBarBackgroundColor

        // set table view cell appearance
        UITableView.appearance().backgroundColor = theme.tableViewBackgroundColor
        UITableViewCell.appearance().backgroundColor = theme.tableViewCellBackgroundColor
        // FIXME: refactor
        // UITableViewCell.appearance(whenContainedInInstancesOf: [SettingsViewController.self]).backgroundColor = theme.secondarySystemGroupedBackgroundColor
        // UITableViewCell.appearance().selectionColor = theme.tableViewCellSelectionBackgroundColor

        // set search bar appearance
        UISearchBar.appearance().tintColor = ThemeService.tintColor
        UISearchBar.appearance().barTintColor = theme.navigationBarBackgroundColor
        let cancelButtonAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: ThemeService.tintColor]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(cancelButtonAttributes, for: .normal)
    }
}
