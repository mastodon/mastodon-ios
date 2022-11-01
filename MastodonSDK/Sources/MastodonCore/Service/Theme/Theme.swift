//
//  Theme.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit
import MastodonCommon

public protocol Theme {

    var themeName: ThemeName { get }
    
    var systemBackgroundColor: UIColor { get }
    var secondarySystemBackgroundColor: UIColor { get }
    var tertiarySystemBackgroundColor: UIColor { get }

    var systemElevatedBackgroundColor: UIColor { get }

    var systemGroupedBackgroundColor: UIColor { get }
    var secondarySystemGroupedBackgroundColor: UIColor { get }
    var tertiarySystemGroupedBackgroundColor: UIColor { get }

    var navigationBarBackgroundColor: UIColor { get }
    
    var sidebarBackgroundColor: UIColor { get }

    var tabBarBackgroundColor: UIColor { get }
    var tabBarItemSelectedIconColor: UIColor { get }
    var tabBarItemFocusedIconColor: UIColor { get }
    var tabBarItemNormalIconColor: UIColor { get }
    var tabBarItemDisabledIconColor: UIColor { get }

    var separator: UIColor { get }

    var tableViewCellBackgroundColor: UIColor { get }
    var tableViewCellSelectionBackgroundColor: UIColor { get }

    var contentWarningOverlayBackgroundColor: UIColor { get }
    var profileFieldCollectionViewBackgroundColor: UIColor { get }
    var composeToolbarBackgroundColor: UIColor { get }
    var composePollRowBackgroundColor: UIColor { get }
    var notificationStatusBorderColor: UIColor { get }

}
