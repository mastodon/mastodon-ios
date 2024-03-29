// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization
import MastodonAsset

enum Tab: Int, CaseIterable {
    case home
    case search
    case compose
    case notifications
    case me

    var tag: Int {
        return rawValue
    }

    var title: String {
        switch self {
        case .home:             return L10n.Common.Controls.Tabs.home
        case .search:           return L10n.Common.Controls.Tabs.searchAndExplore
        case .compose:          return L10n.Common.Controls.Actions.compose
        case .notifications:    return L10n.Common.Controls.Tabs.notifications
        case .me:               return L10n.Common.Controls.Tabs.profile
        }
    }

    var inputLabels: [String]? {
        switch self {
        case .home, .compose, .notifications, .me:
            return nil
        case .search:
            return [
                L10n.Common.Controls.Tabs.A11Y.search,
                L10n.Common.Controls.Tabs.A11Y.explore,
                L10n.Common.Controls.Tabs.searchAndExplore
            ]
        }
    }

    var image: UIImage {
        switch self {
            case .home:             return UIImage(systemName: "house")!
            case .search:           return UIImage(systemName: "magnifyingglass")!
            case .compose:          return UIImage(systemName: "square.and.pencil")!
            case .notifications:    return UIImage(systemName: "bell")!
            case .me:               return UIImage(systemName: "person")!
        }
    }

    var selectedImage: UIImage {
        return image.withTintColor(Asset.Colors.Brand.blurple.color, renderingMode: .alwaysOriginal)
    }

    var largeImage: UIImage {
        return image.withRenderingMode(.alwaysTemplate).resized(size: CGSize(width: 80, height: 80))
    }
}

extension UIViewController {
    func configureTabBarItem(with tab: Tab) {
        title = tab.title
        tabBarItem.tag = tab.tag
        tabBarItem.title = tab.title     // needs for acessiblity large content label
        tabBarItem.image = tab.image.imageWithoutBaseline()
        tabBarItem.largeContentSizeImage = tab.largeImage.imageWithoutBaseline()
        tabBarItem.accessibilityLabel = tab.title
        tabBarItem.accessibilityUserInputLabels = tab.inputLabels
        tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
    }
}
