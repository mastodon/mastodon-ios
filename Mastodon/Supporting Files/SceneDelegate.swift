//
//  SceneDelegate.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/22.
//

import UIKit
import Combine
import CoreDataStack
import MastodonCore
import MastodonExtension
import MastodonUI
import MastodonSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    var window: UIWindow?
    var coordinator: SceneCoordinator?

    var savedShortCutItem: UIApplicationShortcutItem?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        #if DEBUG
        let window = TouchesVisibleWindow(windowScene: windowScene)
        self.window = window
        #else
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        #endif

        // set tint color
        window.tintColor = UIColor.label

        let appContext = AppContext.shared
        let sceneCoordinator = SceneCoordinator(scene: scene, sceneDelegate: self, appContext: appContext)
        self.coordinator = sceneCoordinator
        
        sceneCoordinator.setup()
        window.makeKeyAndVisible()
        
        if let urlContext = connectionOptions.urlContexts.first {
            handleUrl(context: urlContext)
        }

        if let userActivity = connectionOptions.userActivities.first {
            handleUniversalLink(userActivity: userActivity)
        }
        
        #if SNAPSHOT
        // speedup animation
        // window.layer.speed = 999
        
        // disable animation
        UIView.setAnimationsEnabled(false)
        #endif

        if let shortcutItem = connectionOptions.shortcutItem {
            // Save it off for later when we become active.
            savedShortCutItem = shortcutItem
        }
        
        UserDefaults.shared.observe(\.customUserInterfaceStyle, options: [.initial, .new]) { [weak self] defaults, _ in
            guard let self = self else { return }
            #if SNAPSHOT
            // toggle Dark Mode
            // https://stackoverflow.com/questions/32988241/how-to-access-launchenvironment-and-launcharguments-set-in-xcuiapplication-runn
            if ProcessInfo.processInfo.arguments.contains("UIUserInterfaceStyleForceDark") {
                self.window?.overrideUserInterfaceStyle = .dark
            }
            #else
            self.window?.overrideUserInterfaceStyle = defaults.customUserInterfaceStyle
            #endif
        }
        .store(in: &observations)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        // update application badge
        AppContext.shared.notificationService.applicationIconBadgeNeedsUpdate.send()

        // trigger status filter update
        AppContext.shared.statusFilterService.filterUpdatePublisher.send()
        
        // trigger authenticated user account update
        AppContext.shared.authenticationService.updateActiveUserAccountPublisher.send()

        if let shortcutItem = savedShortCutItem {
            Task {
                _ = await handler(shortcutItem: shortcutItem)
            }
            savedShortCutItem = nil
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUniversalLink(userActivity: userActivity)
    }

    private func handleUniversalLink(userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return
        }

        guard let path = components.path, let authContext = coordinator?.authContext else {
            return
        }

        let pathElements = path.split(separator: "/")

        let profile: String?
        if let profileInPath = pathElements[safe: 0] {
            profile = String(profileInPath)
        } else {
            profile = nil
        }

        let statusID: String?
        if let statusIDInPath = pathElements[safe: 1] {
            statusID = String(statusIDInPath)
        } else {
            statusID = nil
        }

        switch (profile, statusID) {
            case (profile, nil):
                Task {
                    let authenticationBox = authContext.mastodonAuthenticationBox

                    guard let me = authenticationBox.authentication.account() else { return }

                    guard let account = try await AppContext.shared.apiService.search(
                        query: .init(q: incomingURL.absoluteString, type: .accounts, resolve: true),
                        authenticationBox: authenticationBox
                    ).value.accounts.first else { return }

                    guard let relationship = try await AppContext.shared.apiService.relationship(
                        forAccounts: [account],
                        authenticationBox: authenticationBox
                    ).value.first else { return }

                    let profileViewModel = ProfileViewModel(
                        context: AppContext.shared,
                        authContext: authContext,
                        account: account,
                        relationship: relationship,
                        me: me
                    )
                    _ = self.coordinator?.present(
                        scene: .profile(viewModel: profileViewModel),
                        from: nil,
                        transition: .show
                    )
                }

            case (profile, statusID):
                Task {
                    guard let statusOnMyInstance = try await AppContext.shared.apiService.search(query: .init(q: incomingURL.absoluteString, resolve: true), authenticationBox: authContext.mastodonAuthenticationBox).value.statuses.first else { return }

                    let threadViewModel = RemoteThreadViewModel(
                        context: AppContext.shared,
                        authContext: authContext,
                        statusID: statusOnMyInstance.id
                    )
                    coordinator?.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
                }

            case (_, _):
                break
                // do nothing
        }

    }
}

extension SceneDelegate {
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
        return await handler(shortcutItem: shortcutItem)
    }

    @MainActor
    private func handler(shortcutItem: UIApplicationShortcutItem) async -> Bool {

        switch shortcutItem.type {
        case NotificationService.unreadShortcutItemIdentifier:
            guard let coordinator = self.coordinator else { return false }

            guard let accessToken = shortcutItem.userInfo?["accessToken"] as? String else {
                assertionFailure()
                return false
            }
            
            guard let authentication = AuthenticationServiceProvider.shared.getAuthentication(matching: accessToken) else {
                assertionFailure()
                return false
            }

            let _isActive = try? await coordinator.appContext.authenticationService.activeMastodonUser(
                domain: authentication.domain,
                userID: authentication.userID
            )
            
            guard _isActive == true else {
                return false
            }

            coordinator.switchToTabBar(tab: .notifications)

        case "org.joinmastodon.app.new-post":
            showComposeViewController()

        case "org.joinmastodon.app.search":
            coordinator?.switchToTabBar(tab: .search)

            if let searchViewController = coordinator?.tabBarController.topMost as? SearchViewController {
                searchViewController.searchBarTapPublisher.send("")
            }

        default:
            assertionFailure()
            break
        }

        return true
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Determine who sent the URL.
        if let urlContext = URLContexts.first {
            handleUrl(context: urlContext)
        }
    }
    
    private func showComposeViewController() {
        if coordinator?.tabBarController.topMost is ComposeViewController {
        } else {
            if let authContext = coordinator?.authContext {
                let composeViewModel = ComposeViewModel(
                    context: AppContext.shared,
                    authContext: authContext,
                    composeContext: .composeStatus,
                    destination: .topLevel
                )
                _ = coordinator?.present(scene: .compose(viewModel: composeViewModel), from: nil, transition: .modal(animated: true, completion: nil))
            }
        }
    }
    
    private func handleUrl(context: UIOpenURLContext) {
        let sendingAppID = context.options.sourceApplication
        let url = context.url

        if !UIApplication.shared.canOpenURL(url) { return }

#if DEBUG
        print("source application = \(sendingAppID ?? "Unknown")")
        print("url = \(url)")
#endif
        
        switch url.host {
        case "post":
            showComposeViewController()
        case "profile":
            let components = url.pathComponents
            guard
                components.count == 2,
                components[0] == "/",
                let authContext = coordinator?.authContext
            else { return }
            
            Task {
                do {
                    let authenticationBox = authContext.mastodonAuthenticationBox
                    
                    guard let me = authContext.mastodonAuthenticationBox.authentication.account() else { return }
                    
                    guard let account = try await AppContext.shared.apiService.search(
                        query: .init(q: components[1], type: .accounts, resolve: true),
                        authenticationBox: authenticationBox
                    ).value.accounts.first else { return }
                    
                    guard let relationship = try await AppContext.shared.apiService.relationship(
                        forAccounts: [account],
                        authenticationBox: authenticationBox
                    ).value.first else { return }
                    
                    let profileViewModel = ProfileViewModel(
                        context: AppContext.shared,
                        authContext: authContext,
                        account: account,
                        relationship: relationship,
                        me: me
                    )
                    
                    self.coordinator?.present(
                        scene: .profile(viewModel: profileViewModel),
                        from: nil,
                        transition: .show
                    )
                } catch {
                    // fail silently
                }
            }
        case "status":
            let components = url.pathComponents
            guard
                components.count == 2,
                components[0] == "/",
                let authContext = coordinator?.authContext
            else { return }
            let statusId = components[1]
            // View post from user
            let threadViewModel = RemoteThreadViewModel(
                context: AppContext.shared,
                authContext: authContext,
                statusID: statusId
            )
            coordinator?.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
        case "search":
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            guard
                let authContext = coordinator?.authContext,
                let searchQuery = queryItems?.first(where: { $0.name == "query" })?.value
            else { return }
            
            let viewModel = SearchDetailViewModel(authContext: authContext, initialSearchText: searchQuery)
            coordinator?.present(scene: .searchDetail(viewModel: viewModel), from: nil, transition: .show)
        default:
            return
        }
    }
}

