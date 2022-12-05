//
//  HomeTimelineViewController+DebugAction.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//


#if DEBUG || SNAPSHOT
import os.log
import UIKit
import CoreData
import CoreDataStack
import FLEX
import SwiftUI
import MastodonCore
import MastodonUI
import MastodonSDK
import StoreKit

extension HomeTimelineViewController {
    var debugMenu: UIMenu {
        let menu = UIMenu(
            title: "Debug Tools",
            image: nil,
            identifier: nil,
            options: .displayInline,
            children: [
                showMenu,
                moveMenu,
                dropMenu,
                miscMenu,
                notificationMenu,
                UIAction(title: "Settings", image: UIImage(systemName: "gear"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showSettings(action)
                },
                UIAction(title: "Sign Out", image: UIImage(systemName: "escape"), attributes: .destructive) { [weak self] action in
                    guard let self = self else { return }
                    self.signOutAction(action)
                }
            ]
        )
        return menu
    }

    var showMenu: UIMenu {
        return UIMenu(
            title: "Show…",
            image: UIImage(systemName: "plus.rectangle.on.rectangle"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "FLEX", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.showFLEXAction(action)
                }),
                UIAction(title: "Welcome", image: UIImage(systemName: "figure.walk"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showWelcomeAction(action)
                },
                UIAction(title: "Register", image: UIImage(systemName: "list.bullet.rectangle.portrait.fill"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showRegisterAction(action)
                },
                UIAction(title: "Confirm Email", image: UIImage(systemName: "envelope"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showConfirmEmail(action)
                },
                UIAction(title: "Account List", image: UIImage(systemName: "person"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showAccountList(action)
                },
                UIAction(title: "Profile", image: UIImage(systemName: "person.crop.circle"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showProfileAction(action)
                },
                UIAction(title: "Thread", image: UIImage(systemName: "bubble.left.and.bubble.right"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showThreadAction(action)
                },
                UIAction(title: "Account Recommend", image: UIImage(systemName: "human"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    let suggestionAccountViewModel = SuggestionAccountViewModel(
                        context: self.context,
                        authContext: self.viewModel.authContext
                    )
                    _ = self.coordinator.present(
                        scene: .suggestionAccount(viewModel: suggestionAccountViewModel),
                        from: self,
                        transition: .modal(animated: true, completion: nil)
                    )
                },
                UIAction(title: "Store Rating", image: UIImage(systemName: "star.fill"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    guard let windowScene = self.view.window?.windowScene else { return }
                    SKStoreReviewController.requestReview(in: windowScene)
                },
            ]
        )
    }
    
    var dropMenu: UIMenu {
        return UIMenu(
            title: "Drop…",
            image: UIImage(systemName: "minus.circle"),
            identifier: nil,
            options: [],
            children: [50, 100, 150, 200, 250, 300].map { count in
                UIAction(title: "Drop Recent \(count) Statuses", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.dropRecentStatusAction(action, count: count)
                })
            }
        )
    }
    
    var miscMenu: UIMenu {
        return UIMenu(
            title: "Debug…",
            image: UIImage(systemName: "switch.2"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "Toggle Visible Touches", image: UIImage(systemName: "hand.tap"), attributes: []) { _ in
                    guard let window = UIApplication.shared.getKeyWindow() as? TouchesVisibleWindow else { return }
                    window.touchesVisible = !window.touchesVisible
                },
                UIAction(title: "Toggle EmptyView", image: UIImage(systemName: "clear"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    if self.emptyView.superview != nil {
                        self.emptyView.removeFromSuperview()
                    } else {
                        self.showEmptyView()
                    }
                },
                UIAction(
                    title: "Enable account switcher wizard",
                    image: UIImage(systemName: "square.stack.3d.down.forward.fill"),
                    identifier: nil,
                    attributes: [],
                    state: .off,
                    handler: { _ in 
                        UserDefaults.shared.didShowMultipleAccountSwitchWizard = false
                    }
                ),
            ]
        )
    }
    
    var notificationMenu: UIMenu {
        return UIMenu(
            title: "Notification…",
            image: UIImage(systemName: "bell.badge"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "Badge +1", image: UIImage(systemName: "app.badge.fill"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    let accessToken = self.viewModel.authContext.mastodonAuthenticationBox.userAuthorization.accessToken
                    UserDefaults.shared.increaseNotificationCount(accessToken: accessToken)
                    self.context.notificationService.applicationIconBadgeNeedsUpdate.send()
                },
                UIAction(title: "Profile", image: UIImage(systemName: "person.badge.plus"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showNotification(action, notificationType: .follow)
                },
                UIAction(title: "Status", image: UIImage(systemName: "list.bullet.rectangle"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showNotification(action, notificationType: .mention)
                },
            ]
        )
    }
    
}

extension HomeTimelineViewController {
    
    enum MoveAction: String, CaseIterable {
        case gap
        case reply
        case mention
        case poll
//        case quote
//        case gif
//        case video
//        case location
//        case followsYouAuthor
//        case blockingAuthor
        
        var title: String {
            return rawValue.capitalized
        }
        
        func match(item: StatusItem) -> Bool {
            // let authenticationBox = AppContext.shared.authenticationService.activeMastodonAuthenticationBox.value
            switch item {
            case .feed(let record):
                guard let feed = record.object(in: AppContext.shared.managedObjectContext) else { return false }
                if let status = feed.status {
                    switch self {
                    case .gap:
                        return false
                    case .reply:
                        return status.inReplyToID != nil
                    case .mention:
                        return !(status.reblog ?? status).mentions.isEmpty
                    case .poll:
                        return (status.reblog ?? status).poll != nil
//                    case .quote:
//                        return status.quote != nil
//                    case .gif:
//                        return status.attachments.contains(where: { attachment in attachment.kind == .animatedGIF })
//                    case .video:
//                        return status.attachments.contains(where: { attachment in attachment.kind == .video })
//                    case .location:
//                        return status.location != nil
//                    case .followsYouAuthor:
//                        guard case let .twitter(authenticationContext) = authenticationContext else { return false }
//                        guard let me = authenticationContext.authenticationRecord.object(in: AppContext.shared.managedObjectContext)?.user else { return false }
//                        return (status.repost ?? status).author.following.contains(me)
//                    case .blockingAuthor:
//                        guard case let .twitter(authenticationContext) = authenticationContext else { return false }
//                        guard let me = authenticationContext.authenticationRecord.object(in: AppContext.shared.managedObjectContext)?.user else { return false }
//                        return (status.repost ?? status).author.blockingBy.contains(me)
//                    default:
//                        return false
                    }   // end switch
                } else {
                    return false
                }
            case .feedLoader where self == .gap:
                return true
            default:
                return false
            }
        }
        
        func firstMatch(in items: [StatusItem]) -> StatusItem? {
            return items.first { item in self.match(item: item) }
        }
    }
    
    var moveMenu: UIMenu {
        return UIMenu(
            title: "Move to…",
            image: UIImage(systemName: "arrow.forward.circle"),
            identifier: nil,
            options: [],
            children:
                MoveAction.allCases.map { moveAction in
                    UIAction(title: "First \(moveAction.title)", image: nil, attributes: []) { [weak self] action in
                        guard let self = self else { return }
                        self.moveToFirst(action, moveAction: moveAction)
                    }
                }
        )
    }
    
    private func moveToFirst(_ sender: UIAction, moveAction: MoveAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        let items = snapshot.itemIdentifiers
        guard let targetItem = moveAction.firstMatch(in: items),
              let index = snapshot.indexOfItem(targetItem)
        else { return }
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        tableView.blinkRow(at: indexPath)
    }
    
}

extension HomeTimelineViewController {
    
    @objc private func showFLEXAction(_ sender: UIAction) {
        FLEXManager.shared.showExplorer()
    }
    
    @objc private func dropRecentStatusAction(_ sender: UIAction, count: Int) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        
        let feedRecords = snapshot.itemIdentifiers.prefix(count).compactMap { item -> ManagedObjectRecord<Feed>? in
            switch item {
            case .feed(let record):                     return record
            default:                                    return nil
            }
        }
        let managedObjectContext = viewModel.context.backgroundManagedObjectContext
        Task {
            try await managedObjectContext.performChanges {
                for record in feedRecords {
                    guard let feed = record.object(in: managedObjectContext) else { continue }
                    let status = feed.status
                    managedObjectContext.delete(feed)
                    if let status = status {
                        managedObjectContext.delete(status)
                    }
                }   // end for in 
            }   // end managedObjectContext.performChanges
        }   // end Task
    }
    
    @objc private func showWelcomeAction(_ sender: UIAction) {
        _ = coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func showRegisterAction(_ sender: UIAction) {
        Task { @MainActor in
            try await showRegisterController()
        }   // end Task
    }
    
    @MainActor
    func showRegisterController(domain: String = "mstdn.jp") async throws {
        let viewController = try await MastodonRegisterViewController.create(
            context: context,
            coordinator: coordinator,
            domain: "mstdn.jp"
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true) {
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction(handler: { [weak viewController] _ in
                    guard let viewController = viewController else { return }
                    viewController.dismiss(animated: true)
                }),
                menu: nil
            )
        }
    }

    @objc private func showConfirmEmail(_ sender: UIAction) {
        let mastodonConfirmEmailViewModel = MastodonConfirmEmailViewModel()
        _ = coordinator.present(scene: .mastodonConfirmEmail(viewModel: mastodonConfirmEmailViewModel), from: nil, transition: .modal(animated: true, completion: nil))
    }

    @objc private func showAccountList(_ sender: UIAction) {
        let accountListViewModel = AccountListViewModel(context: context, authContext: viewModel.authContext)
        _ = coordinator.present(scene: .accountList(viewModel: accountListViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func showProfileAction(_ sender: UIAction) {
        let alertController = UIAlertController(title: "Enter User ID", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        let showAction = UIAlertAction(title: "Show", style: .default) { [weak self, weak alertController] _ in
            guard let self = self else { return }
            guard let textField = alertController?.textFields?.first else { return }
            let profileViewModel = RemoteProfileViewModel(context: self.context, authContext: self.viewModel.authContext, userID: textField.text ?? "")
            _ = self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
        }
        alertController.addAction(showAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        _ = coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }
    
    @objc private func showThreadAction(_ sender: UIAction) {
        let alertController = UIAlertController(title: "Enter Status ID", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        let showAction = UIAlertAction(title: "Show", style: .default) { [weak self, weak alertController] _ in
            guard let self = self else { return }
            guard let textField = alertController?.textFields?.first else { return }
            let threadViewModel = RemoteThreadViewModel(context: self.context, authContext: self.viewModel.authContext, statusID: textField.text ?? "")
            _ = self.coordinator.present(scene: .thread(viewModel: threadViewModel), from: self, transition: .show)
        }
        alertController.addAction(showAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        _ = coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
    }
    
    private func showNotification(_ sender: UIAction, notificationType: Mastodon.Entity.Notification.NotificationType) {
        let alertController = UIAlertController(title: "Enter notification ID", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        
        let showAction = UIAlertAction(title: "Show", style: .default) { [weak self, weak alertController] _ in
            guard let self = self else { return }
            guard let textField = alertController?.textFields?.first,
                  let text = textField.text,
                  let notificationID = Int(text)
            else { return }
            
            let pushNotification = MastodonPushNotification(
                accessToken: self.viewModel.authContext.mastodonAuthenticationBox.userAuthorization.accessToken,
                notificationID: notificationID,
                notificationType: notificationType.rawValue,
                preferredLocale: nil,
                icon: nil,
                title: "",
                body: ""
            )
            self.context.notificationService.requestRevealNotificationPublisher.send(pushNotification)
        }
        alertController.addAction(showAction)
        
        // for multiple accounts debug
        let boxes = self.context.authenticationService.mastodonAuthenticationBoxes    // already sorted
        if boxes.count >= 2 {
            let accessToken = boxes[1].userAuthorization.accessToken
            let showForSecondaryAction = UIAlertAction(title: "Show for Secondary", style: .default) { [weak self, weak alertController] _ in
                guard let self = self else { return }
                guard let textField = alertController?.textFields?.first,
                      let text = textField.text,
                      let notificationID = Int(text)
                else { return }
                
                let pushNotification = MastodonPushNotification(
                    accessToken: accessToken,
                    notificationID: notificationID,
                    notificationType: notificationType.rawValue,
                    preferredLocale: nil,
                    icon: nil,
                    title: "",
                    body: ""
                )
                self.context.notificationService.requestRevealNotificationPublisher.send(pushNotification)
            }
            alertController.addAction(showForSecondaryAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        _ = self.coordinator.present(
            scene: .alertController(alertController: alertController),
            from: self,
            transition: .alertController(animated: true, completion: nil)
        )
    }
    
    @objc private func showSettings(_ sender: UIAction) {
        guard let currentSetting = context.settingService.currentSetting.value else { return }
        let settingsViewModel = SettingsViewModel(
            context: context,
            authContext: viewModel.authContext,
            setting: currentSetting
        )
        _ = coordinator.present(
            scene: .settings(viewModel: settingsViewModel),
            from: self,
            transition: .modal(animated: true, completion: nil)
        )
    }

}
#endif
