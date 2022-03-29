//
//  NotificationViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/12.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import Pageboy

final class NotificationViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let viewDidLoad = PassthroughSubject<Void, Never>()
    
    // output
    let scopes = NotificationTimelineViewModel.Scope.allCases
    @Published var viewControllers: [UIViewController] = []
    @Published var currentPageIndex = 0

    
    init(context: AppContext) {
        self.context = context
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

//    func acceptFollowRequest(notification: MastodonNotification) {
//        guard let activeMastodonAuthenticationBox = self.activeMastodonAuthenticationBox.value else { return }
//        context.apiService.acceptFollowRequest(mastodonUserID: notification.account.id, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
//            .sink { [weak self] completion in
//                switch completion {
//                case .failure(let error):
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: accept FollowRequest fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                case .finished:
//                    break
////                    self?.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self)
//                }
//            } receiveValue: { _ in
//
//            }
//            .store(in: &disposeBag)
//    }
//
//    func rejectFollowRequest(notification: MastodonNotification) {
//        guard let activeMastodonAuthenticationBox = self.activeMastodonAuthenticationBox.value else { return }
//        context.apiService.rejectFollowRequest(mastodonUserID: notification.account.id, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
//            .sink { [weak self] completion in
//                switch completion {
//                case .failure(let error):
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: reject FollowRequest fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                case .finished:
//                    break
////                    self?.loadLatestStateMachine.enter(NotificationViewModel.LoadLatestState.Loading.self)
//                }
//            } receiveValue: { _ in
//
//            }
//            .store(in: &disposeBag)
//    }
//}


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

