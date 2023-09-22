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
    // MARK: - Singleton
    public static let shared = ThemeService()

    public func apply() {
        // set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = SystemTheme.navigationBarBackgroundColor
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
        tabBarItemAppearance.selected.iconColor = SystemTheme.tabBarItemSelectedIconColor
        tabBarItemAppearance.focused.iconColor = SystemTheme.tabBarItemFocusedIconColor
        tabBarItemAppearance.normal.iconColor = SystemTheme.tabBarItemNormalIconColor
        tabBarItemAppearance.disabled.iconColor = SystemTheme.tabBarItemDisabledIconColor
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance

        tabBarAppearance.backgroundColor = SystemTheme.tabBarBackgroundColor
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().barTintColor = SystemTheme.tabBarBackgroundColor

        // set table view cell appearance
        UITableView.appearance().backgroundColor = SystemTheme.tableViewBackgroundColor
        UITableViewCell.appearance().backgroundColor = SystemTheme.tableViewCellBackgroundColor
        // FIXME: refactor
        // UITableViewCell.appearance(whenContainedInInstancesOf: [SettingsViewController.self]).backgroundColor = .secondarySystemGroupedBackground
        // UITableViewCell.appearance().selectionColor = SystemTheme.tableViewCellSelectionBackgroundColor

        // set search bar appearance
        UISearchBar.appearance().tintColor = SystemTheme.tintColor
        UISearchBar.appearance().barTintColor = SystemTheme.navigationBarBackgroundColor
        let cancelButtonAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: SystemTheme.tintColor]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(cancelButtonAttributes, for: .normal)
    }
}
