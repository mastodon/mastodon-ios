//
//  NotificationViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/12.
//

import os.log
import UIKit
import Combine
import Pageboy
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class NotificationViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let viewDidLoad = PassthroughSubject<Void, Never>()
    
    // output
    let scopes = NotificationTimelineViewModel.Scope.allCases
    @Published var viewControllers: [UIViewController] = []
    @Published var currentPageIndex = 0

    
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        // end init
    }
}
    
extension NotificationTimelineViewModel.Scope {
    var title: String {
        switch self {
        case .everything:
            return L10n.Scene.Notification.Title.everything
        case .mentions:
            return L10n.Scene.Notification.Title.mentions
        }
    }
}

// MARK: - PageboyViewControllerDataSource
extension NotificationViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }
    
}

