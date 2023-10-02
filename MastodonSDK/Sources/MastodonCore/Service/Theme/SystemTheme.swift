//
//  SystemTheme.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import MastodonAsset
import MastodonCommon

public enum SystemTheme {
    public static let tintColor = UIColor.label

    public static let systemElevatedBackgroundColor = Asset.Theme.System.systemElevatedBackground.color
    public static let navigationBarBackgroundColor = Asset.Theme.System.navigationBarBackground.color

    public static let sidebarBackgroundColor = Asset.Theme.System.sidebarBackground.color
    
    public static let tabBarBackgroundColor = Asset.Theme.System.tabBarBackground.color
    public static let tabBarItemSelectedIconColor = Asset.Colors.Brand.blurple.color
    public static let tabBarItemFocusedIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
    public static let tabBarItemNormalIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
    public static let tabBarItemDisabledIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color

    public static let separator = Asset.Theme.System.separator.color

    public static let tableViewBackgroundColor: UIColor = .clear
    public static let tableViewCellBackgroundColor = Asset.Theme.System.tableViewCellBackground.color
    public static let tableViewCellSelectionBackgroundColor = Asset.Theme.System.tableViewCellSelectionBackground.color

    public static let contentWarningOverlayBackgroundColor = Asset.Theme.System.contentWarningOverlayBackground.color
    public static let composeToolbarBackgroundColor = Asset.Theme.System.composeToolbarBackground.color
    public static let composePollRowBackgroundColor = Asset.Theme.System.composePollRowBackground.color
}
