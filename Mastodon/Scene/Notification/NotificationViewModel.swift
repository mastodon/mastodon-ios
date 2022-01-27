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
//    let selectedIndex = CurrentValueSubject<NotificationSegment, Never>(.everyThing)
//    let noMoreNotification = CurrentValueSubject<Bool, Never>(false)
    
//    let activeMastodonAuthenticationBox: CurrentValueSubject<MastodonAuthenticationBox?, Never>
//    let fetchedResultsController: NSFetchedResultsController<MastodonNotification>!
//    let notificationPredicate = CurrentValueSubject<NSPredicate?, Never>(nil)
//    let cellFrameCache = NSCache<NSNumber, NSValue>()
    
//    var needsScrollToTopAfterDataSourceUpdate = false
//    let dataSourceDidUpdated = PassthroughSubject<Void, Never>()
//    let isFetchingLatestNotification = CurrentValueSubject<Bool, Never>(false)
    
    
    // output
    let scopes = NotificationTimelineViewModel.Scope.allCases
    @Published var viewControllers: [UIViewController] = []
    @Published var currentPageIndex = 0

    
    init(context: AppContext) {
        self.context = context
//        self.activeMastodonAuthenticationBox = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value)
//        self.fetchedResultsController = {
//            let fetchRequest = MastodonNotification.sortedFetchRequest
//            fetchRequest.returnsObjectsAsFaults = false
//            fetchRequest.fetchBatchSize = 10
//            fetchRequest.relationshipKeyPathsForPrefetching = [#keyPath(MastodonNotification.status), #keyPath(MastodonNotification.account)]
//            let controller = NSFetchedResultsController(
//                fetchRequest: fetchRequest,
//                managedObjectContext: context.managedObjectContext,
//                sectionNameKeyPath: nil,
//                cacheName: nil
//            )
//
//            return controller
//        }()
        // end init
        
//        fetchedResultsController.delegate = self
//        context.authenticationService.activeMastodonAuthenticationBox
//            .sink(receiveValue: { [weak self] box in
//                guard let self = self else { return }
//                self.activeMastodonAuthenticationBox.value = box
//                if let domain = box?.domain, let userID = box?.userID {
//                    self.notificationPredicate.value = MastodonNotification.predicate(domain: domain, userID: userID)
//                }
//            })
//            .store(in: &disposeBag)
        
//        notificationPredicate
//            .compactMap { $0 }
//            .sink { [weak self] predicate in
//                guard let self = self else { return }
//                self.fetchedResultsController.fetchRequest.predicate = predicate
//                do {
//                    self.diffableDataSource?.defaultRowAnimation = .fade
//                    try self.fetchedResultsController.performFetch()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
//                        guard let self = self else { return }
//                        self.diffableDataSource?.defaultRowAnimation = .automatic
//                    }
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                }
//            }
//            .store(in: &disposeBag)
        
//        viewDidLoad
//            .sink { [weak self] in
//
//                guard let domain = self?.activeMastodonAuthenticationBox.value?.domain, let userID = self?.activeMastodonAuthenticationBox.value?.userID else { return }
//                self?.notificationPredicate.value = MastodonNotification.predicate(domain: domain, userID: userID)
//            }
//            .store(in: &disposeBag)
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

