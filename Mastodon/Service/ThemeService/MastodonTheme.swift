//
//  MastodonTheme.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit

struct MastodonTheme: Theme {
    let systemBackgroundColor = Asset.Theme.Mastodon.systemBackground.color
    let secondarySystemBackgroundColor = Asset.Theme.Mastodon.secondarySystemBackground.color
    let tertiarySystemBackgroundColor = Asset.Theme.Mastodon.tertiarySystemBackground.color

    let systemElevatedBackgroundColor = Asset.Theme.Mastodon.systemElevatedBackground.color

    let systemGroupedBackgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color
    let secondarySystemGroupedBackgroundColor = Asset.Theme.Mastodon.secondaryGroupedSystemBackground.color
    let tertiarySystemGroupedBackgroundColor = Asset.Theme.Mastodon.tertiarySystemGroupedBackground.color

    let navigationBarBackgroundColor = Asset.Theme.Mastodon.navigationBarBackground.color

    let tabBarBackgroundColor = Asset.Theme.Mastodon.tabBarBackground.color
    let tabBarItemSelectedIconColor = Asset.Colors.brandBlue.color
    let tabBarItemFocusedIconColor = Asset.Theme.Mastodon.tabBarItemInactiveIconColor.color
    let tabBarItemNormalIconColor = Asset.Theme.Mastodon.tabBarItemInactiveIconColor.color
    let tabBarItemDisabledIconColor = Asset.Theme.Mastodon.tabBarItemInactiveIconColor.color

    let separator = Asset.Theme.Mastodon.separator.color

    let tableViewCellBackgroundColor = Asset.Theme.Mastodon.tableViewCellBackground.color
    let tableViewCellSelectionBackgroundColor = Asset.Theme.Mastodon.tableViewCellSelectionBackground.color
    
    let contentWarningOverlayBackgroundColor = Asset.Theme.Mastodon.contentWarningOverlayBackground.color
    let profileFieldCollectionViewBackgroundColor = Asset.Theme.Mastodon.profileFieldCollectionViewBackground.color
}
