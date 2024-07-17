//
//  NotificationViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/12.
//

import UIKit
import Combine
import Pageboy
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK

final class NotificationViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    var notificationPolicy: Mastodon.Entity.NotificationPolicy?
    let viewDidLoad = PassthroughSubject<Void, Never>()
    
    // output
    @Published var viewControllers: [UIViewController] = []
    @Published var currentPageIndex = 0 {
        didSet {
            lastPageIndex = currentPageIndex
        }
    }
    
    private var lastPageIndex: Int {
        get {
            guard let selectedTabName = UserDefaults.shared.getLastSelectedNotificationsTabName(
                accessToken: authContext.mastodonAuthenticationBox.userAuthorization.accessToken
            ), let scope = APIService.MastodonNotificationScope(rawValue: selectedTabName) else {
                return 0
            }
            
            return APIService.MastodonNotificationScope.allCases.firstIndex(of: scope) ?? 0
        }
        set {
            UserDefaults.shared.setLastSelectedNotificationsTabName(
                accessToken: authContext.mastodonAuthenticationBox.userAuthorization.accessToken,
                value: APIService.MastodonNotificationScope.allCases[newValue].rawValue
            )
        }
    }

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext

        // end init
        Task {
            do {
                let policy = try await context.apiService.notificationPolicy(authenticationBox: authContext.mastodonAuthenticationBox)
                self.notificationPolicy = policy.value
            } catch {
                // we won't show the filtering-options.
            }
        }
    }
}
    
extension NotificationTimelineViewModel.Scope {
    var title: String {
        switch self {
        case .everything:
            return L10n.Scene.Notification.Title.everything
        case .mentions:
            return L10n.Scene.Notification.Title.mentions
        case .fromAccount(let account):
            return "Notifications from \(account.displayName)"
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
        guard
            let pageCount = pageboyViewController.pageCount,
            pageCount > 1,
            (0...(pageCount - 1)).contains(lastPageIndex)
        else {
            return .first /// this should never happen, but in case we somehow manage to acquire invalid data in `lastPageIndex` let's make sure not to crash the app.
        }
        return .at(index: lastPageIndex)
    }
    
}

