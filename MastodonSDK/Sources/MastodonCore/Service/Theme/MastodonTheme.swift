//
//  MastodonTheme.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import MastodonAsset
import MastodonCommon

struct MastodonTheme: Theme {

    let themeName: ThemeName = .mastodon

    let systemBackgroundColor = Asset.Theme.Mastodon.systemBackground.color
    let secondarySystemBackgroundColor = Asset.Theme.Mastodon.secondarySystemBackground.color
    let tertiarySystemBackgroundColor = Asset.Theme.Mastodon.tertiarySystemBackground.color

    let systemElevatedBackgroundColor = Asset.Theme.Mastodon.systemElevatedBackground.color

    let systemGroupedBackgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color
    let secondarySystemGroupedBackgroundColor = Asset.Theme.Mastodon.secondaryGroupedSystemBackground.color
    let tertiarySystemGroupedBackgroundColor = Asset.Theme.Mastodon.tertiarySystemGroupedBackground.color

    let navigationBarBackgroundColor = Asset.Theme.Mastodon.navigationBarBackground.color
    
    let sidebarBackgroundColor = Asset.Theme.Mastodon.sidebarBackground.color

    let tabBarBackgroundColor = Asset.Theme.Mastodon.tabBarBackground.color
    let tabBarItemSelectedIconColor = ThemeService.tintColor
    let tabBarItemFocusedIconColor = Asset.Theme.Mastodon.tabBarItemInactiveIconColor.color
    let tabBarItemNormalIconColor = Asset.Theme.Mastodon.tabBarItemInactiveIconColor.color
    let tabBarItemDisabledIconColor = Asset.Theme.Mastodon.tabBarItemInactiveIconColor.color

    let separator = Asset.Theme.Mastodon.separator.color

    let tableViewCellBackgroundColor = Asset.Theme.Mastodon.tableViewCellBackground.color
    let tableViewCellSelectionBackgroundColor = Asset.Theme.Mastodon.tableViewCellSelectionBackground.color
    
    let contentWarningOverlayBackgroundColor = Asset.Theme.Mastodon.contentWarningOverlayBackground.color
    let profileFieldCollectionViewBackgroundColor = Asset.Theme.Mastodon.profileFieldCollectionViewBackground.color
    let composeToolbarBackgroundColor = Asset.Theme.Mastodon.composeToolbarBackground.color
    let composePollRowBackgroundColor = Asset.Theme.Mastodon.composePollRowBackground.color
    let notificationStatusBorderColor = Asset.Theme.System.notificationStatusBorderColor.color
}
