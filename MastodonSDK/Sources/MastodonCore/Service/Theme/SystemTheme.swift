//
//  SystemTheme.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import MastodonAsset
import MastodonCommon

public struct SystemTheme {
    public let systemBackgroundColor = UIColor.systemBackground
    public let secondarySystemBackgroundColor = UIColor.secondarySystemBackground
    public let tertiarySystemBackgroundColor = UIColor.tertiarySystemBackground

    public let systemElevatedBackgroundColor = Asset.Theme.System.systemElevatedBackground.color

    public let systemGroupedBackgroundColor = UIColor.systemGroupedBackground
    public let secondarySystemGroupedBackgroundColor = UIColor.secondarySystemGroupedBackground
    public let tertiarySystemGroupedBackgroundColor = UIColor.tertiarySystemGroupedBackground

    public let navigationBarBackgroundColor = Asset.Theme.System.navigationBarBackground.color

    public let sidebarBackgroundColor = Asset.Theme.System.sidebarBackground.color
    
    public let tabBarBackgroundColor = Asset.Theme.System.tabBarBackground.color
    public let tabBarItemSelectedIconColor = Asset.Colors.Brand.blurple.color
    public let tabBarItemFocusedIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
    public let tabBarItemNormalIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color
    public let tabBarItemDisabledIconColor = Asset.Theme.System.tabBarItemInactiveIconColor.color

    public let separator = Asset.Theme.System.separator.color

    public let tableViewBackgroundColor: UIColor = .clear
    public let tableViewCellBackgroundColor = Asset.Theme.System.tableViewCellBackground.color
    public let tableViewCellSelectionBackgroundColor = Asset.Theme.System.tableViewCellSelectionBackground.color

    public let contentWarningOverlayBackgroundColor = Asset.Theme.System.contentWarningOverlayBackground.color
    public let profileFieldCollectionViewBackgroundColor = Asset.Theme.System.profileFieldCollectionViewBackground.color
    public let composeToolbarBackgroundColor = Asset.Theme.System.composeToolbarBackground.color
    public let composePollRowBackgroundColor = Asset.Theme.System.composePollRowBackground.color
    public let notificationStatusBorderColor = Asset.Theme.System.notificationStatusBorderColor.color
}
