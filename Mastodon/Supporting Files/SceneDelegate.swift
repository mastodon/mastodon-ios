//
//  SceneDelegate.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/22.
//

import os.log
import UIKit
import Combine
import CoreDataStack

#if DEBUG
import FPSIndicator
#endif

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    var window: UIWindow?
    var coordinator: SceneCoordinator?

    #if DEBUG
    var fpsIndicator: FPSIndicator?
    #endif

    var savedShortCutItem: UIApplicationShortcutItem?

    let logger = Logger(subsystem: "SceneDelegate", category: "logic")

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // set tint color
        window.tintColor = UIColor.label

        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink { [weak self] theme in
                guard let self = self else { return }
                guard let window = self.window else { return }
                window.subviews.forEach { view in
                    view.removeFromSuperview()
                    window.addSubview(view)
                }
            }
            .store(in: &disposeBag)
        
        let appContext = AppContext.shared
        let sceneCoordinator = SceneCoordinator(scene: scene, sceneDelegate: self, appContext: appContext)
        self.coordinator = sceneCoordinator
        
        sceneCoordinator.setup()
        sceneCoordinator.setupOnboardingIfNeeds(animated: false)
        window.makeKeyAndVisible()

        if let shortcutItem = connectionOptions.shortcutItem {
            // Save it off for later when we become active.
            savedShortCutItem = shortcutItem
        }
        
        UserDefaults.shared.observe(\.customUserInterfaceStyle, options: [.initial, .new]) { [weak self] defaults, _ in
            guard let self = self else { return }
            self.window?.overrideUserInterfaceStyle = defaults.customUserInterfaceStyle
        }
        .store(in: &observations)

        #if DEBUG
        fpsIndicator = FPSIndicator(windowScene: windowScene)
        #endif
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        // update application badge
        AppContext.shared.notificationService.applicationIconBadgeNeedsUpdate.send()

        // trigger status filter update
        AppContext.shared.statusFilterService.filterUpdatePublisher.send()

        if let shortcutItem = savedShortCutItem {
            _ = handler(shortcutItem: shortcutItem)
            savedShortCutItem = nil
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        AppContext.shared.audioPlaybackService.pauseIfNeed()
    }

}

extension SceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handler(shortcutItem: shortcutItem))
    }

    private func handler(shortcutItem: UIApplicationShortcutItem) -> Bool {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(shortcutItem.type)")

        switch shortcutItem.type {
        case "org.joinmastodon.app.new-post":
            if coordinator?.tabBarController.topMost is ComposeViewController {
                logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): composing…")
            } else {
                if AppContext.shared.authenticationService.activeMastodonAuthenticationBox.value == nil {
                    logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): not authenticated")
                } else {
                    let composeViewModel = ComposeViewModel(context: AppContext.shared, composeKind: .post)
                    coordinator?.present(scene: .compose(viewModel: composeViewModel), from: nil, transition: .modal(animated: true, completion: nil))
                    logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): present compose scene")
                }
            }
        case "org.joinmastodon.app.search":
            coordinator?.switchToTabBar(tab: .search)
            logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select search tab")

            if let searchViewController = coordinator?.tabBarController.topMost as? SearchViewController {
                searchViewController.searchBarTapPublisher.send()
                logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): trigger search")
            }
        default:
            assertionFailure()
            break
        }

        return true
    }
}
