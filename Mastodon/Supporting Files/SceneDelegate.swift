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
    
    static private var delegates = [ ObjectIdentifier : SceneDelegate ]()
    
    static func assign(delegate: SceneDelegate, to windowScene: UIWindowScene) {
        delegates[ObjectIdentifier(windowScene)] = delegate
    }
    
    static func delegate(for view: UIView) -> SceneDelegate? {
        guard let windowScene = view.window?.windowScene else {
            return nil
        }
        return delegates[ObjectIdentifier(windowScene)]
    }

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    var window: UIWindow?
    var coordinator: SceneCoordinator?

    var savedShortCutItem: UIApplicationShortcutItem?
    
    let feedbackGenerator = FeedbackGenerator.shared

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        feedbackGenerator.isEnabled = false // Disable Haptic Feedback for now
        
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
        
        SceneDelegate.assign(delegate: self, to: windowScene)
        
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
        NotificationService.shared.applicationIconBadgeNeedsUpdate.send()

        // trigger status filter update
        StatusFilterService.shared.filterUpdatePublisher.send()
        
        // trigger authenticated user account update
        AuthenticationServiceProvider.shared.updateActiveUserAccountPublisher.send()

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
              let incomingURL = userActivity.webpageURL else { return }
        openUniversalLink(incomingURL)
    }
    
    private func openUniversalLink(_ incomingURL: URL) {
        guard let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return
        }

        guard let path = components.path, let authenticationBox = coordinator?.authenticationBox else {
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
                    guard let me = authenticationBox.cachedAccount else { return }

                    guard let account = try await APIService.shared.search(
                        query: .init(q: incomingURL.absoluteString, type: .accounts, resolve: true),
                        authenticationBox: authenticationBox
                    ).value.accounts.first else { return }

                    guard let relationship = try await APIService.shared.relationship(
                        forAccounts: [account],
                        authenticationBox: authenticationBox
                    ).value.first else { return }

                    let profileType: ProfileViewController.ProfileType = me == account ? .me(me) : .notMe(me: me, displayAccount: account, relationship: relationship)
                    _ = self.coordinator?.present(
                        scene: .profile(profileType),
                        from: nil,
                        transition: .show
                    )
                }

            case (profile, statusID):
                Task {
                    guard let statusOnMyInstance = try await APIService.shared.search(query: .init(q: incomingURL.absoluteString, resolve: true), authenticationBox: authenticationBox).value.statuses.first else { return }

                    let threadViewModel = RemoteThreadViewModel(
                        authenticationBox: authenticationBox,
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

            let _isActive = AuthenticationServiceProvider.shared.activateExistingUser(authentication.userID,
                inDomain: authentication.domain
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
            if let authenticationBox = coordinator?.authenticationBox {
                let composeViewModel = ComposeViewModel(
                    authenticationBox: authenticationBox,
                    composeContext: .composeStatus(quoting: nil),
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
                let authenticationBox = coordinator?.authenticationBox
            else { return }
            
            Task {
                do {
                    guard let me = authenticationBox.cachedAccount else { return }
                    
                    guard let account = try await APIService.shared.search(
                        query: .init(q: components[1], type: .accounts, resolve: true),
                        authenticationBox: authenticationBox
                    ).value.accounts.first else { return }
                    
                    guard let relationship = try await APIService.shared.relationship(
                        forAccounts: [account],
                        authenticationBox: authenticationBox
                    ).value.first else { return }
                    
                    let profileType: ProfileViewController.ProfileType = me == account ? .me(me) : .notMe(me: me, displayAccount: account, relationship: relationship)
                    self.coordinator?.present(
                        scene: .profile(profileType),
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
                let authenticationBox = coordinator?.authenticationBox
            else { return }
            let statusId = components[1]
            // View post from user
            let threadViewModel = RemoteThreadViewModel(
                authenticationBox: authenticationBox,
                statusID: statusId
            )
            coordinator?.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
        case "search":
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            guard
                let authenticationBox = coordinator?.authenticationBox,
                let searchQuery = queryItems?.first(where: { $0.name == "query" })?.value
            else { return }
            
            let viewModel = SearchDetailViewModel(authenticationBox: authenticationBox, initialSearchText: searchQuery)
            coordinator?.present(scene: .searchDetail(viewModel: viewModel), from: nil, transition: .show)
        default:
            var openableUrl: URL?
            if let host = url.host(percentEncoded: false) {
                openableUrl = URL(string: "https://" + host)
            } else {
                openableUrl = URL(string: "https://")
            }
            openableUrl?.append(path: url.path())
            guard let openableUrl else { return }
            openUniversalLink(openableUrl)
            return
        }
    }
}

