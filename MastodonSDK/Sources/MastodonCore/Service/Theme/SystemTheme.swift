//
//  SystemTheme.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import MastodonAsset
import MastodonCommon

struct SystemTheme: Theme {

    let themeName: ThemeName = .system

    let systemBackgroundColor = Asset.Theme.System.systemBackground.color
    let secondarySystemBackgroundColor = Asset.Theme.System.secondarySystemBackground.color
    let tertiarySystemBackgroundColor = Asset.Theme.System.tertiarySystemBackground.color

    let systemElevatedBackgroundColor = Asset.Theme.System.systemElevatedBackground.color

    let systemGroupedBackgroundColor = Asset.Theme.System.systemGroupedBackground.color
    let secondarySystemGroupedBackgroundColor = Asset.Theme.System.secondaryGroupedSystemBackground.color
    let tertiarySystemGroupedBackgroundColor = Asset.Theme.System.tertiarySystemGroupedBackground.color

    let navigationBarBackgroundColor = Asset.Theme.System.navigationBarBackground.color

    let sidebarBackgroundColor = Asset.Theme.System.sidebarBackground.color
    
    let tabBarBackgroundColor = Asset.Theme.System.tabBarBackground.color
    let tabBarItemSelectedIconColor = ThemeService.tintColor
    let tabBarItemFocusedIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
    let tabBarItemNormalIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
    let tabBarItemDisabledIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color

    let separator = Asset.Theme.System.separator.color

    let tableViewCellBackgroundColor = Asset.Theme.System.tableViewCellBackground.color
    let tableViewCellSelectionBackgroundColor = Asset.Theme.System.tableViewCellSelectionBackground.color

    let contentWarningOverlayBackgroundColor = Asset.Theme.System.contentWarningOverlayBackground.color
    let profileFieldCollectionViewBackgroundColor = Asset.Theme.System.profileFieldCollectionViewBackground.color
    let composeToolbarBackgroundColor = Asset.Theme.System.composeToolbarBackground.color
    let composePollRowBackgroundColor = Asset.Theme.System.composePollRowBackground.color
    let notificationStatusBorderColor = Asset.Theme.System.notificationStatusBorderColor.color
}
