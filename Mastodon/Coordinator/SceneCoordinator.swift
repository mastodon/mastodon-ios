//
//  SceneCoordinator.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.

import UIKit
import Combine
import SafariServices
import MastodonSDK
import MastodonCore
import MastodonAsset
import MastodonLocalization
import MBProgressHUD
import SwiftUI

@MainActor
final public class SceneCoordinator {
    
    fileprivate static func coordinator(for view: UIView) -> SceneCoordinator? {
        return SceneDelegate.delegate(for: view)?.coordinator
    }
    
    private var disposeBag = Set<AnyCancellable>()
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    
    var authenticationBox: MastodonAuthenticationBox? {
        AuthenticationServiceProvider.shared.currentActiveUser.value
    }
    
    let id = UUID().uuidString
    
    private(set) weak var rootViewController: UIViewController?

    private(set) var secondaryStackHashValues = Set<Int>()
    var childCoordinator: Coordinator?

    private var mastodonAuthenticationController: MastodonAuthenticationController?
    
    init(
        scene: UIScene,
        sceneDelegate: SceneDelegate,
        appContext: AppContext
    ) {
        self.scene = scene
        self.sceneDelegate = sceneDelegate

        NotificationService.shared.requestRevealNotificationPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                [weak self] pushNotification in
                guard let self else { return }
                Task { @MainActor in
                    guard let currentActiveAuthenticationBox = self.authenticationBox else { return }
                    let accessToken = pushNotification.accessToken     // use raw accessToken value without normalize
                    if currentActiveAuthenticationBox.userAuthorization.accessToken == accessToken {
                        // do nothing if notification for current account
                        return
                    } else {
                        // switch to notification's account
                        do {
                            guard let authenticationBox = AuthenticationServiceProvider.shared.activateExistingUserToken(accessToken) else {
                                return
                            }

                            self.setup()
                            try await Task.sleep(nanoseconds: .nanosPerUnit * 1)

                            // redirect to notifications tab
                            self.switchToTabBar(tab: .notifications)

                            // show notification related content
                            guard let type = Mastodon.Entity.NotificationType(rawValue: pushNotification.notificationType) else { return }
                            guard let me = authenticationBox.cachedAccount else { return }
                            let notificationID = String(pushNotification.notificationID)

                            switch type {
                            case .follow:
                                let account = try await APIService.shared.notification(
                                    notificationID: notificationID,
                                    authenticationBox: authenticationBox
                                ).value.account

                                let relationshipEntity = try await APIService.shared.relationship(forAccounts: [account], authenticationBox: authenticationBox).value.first

                                let relationship: MastodonAccount.Relationship? = {
                                    guard let relationshipEntity else { return nil }
                                    if me == account {
                                        return .isMe
                                    } else {
                                        return .isNotMe(MastodonAccount.RelationshipInfo(relationshipEntity, fetchedAt: .now))
                                    }
                                }()
                                MastodonTabViewRouter.current.show(.profile(account: account, relationship: relationship), in: .notifications)
                            case .followRequest:
                                // do nothing
                                break
                            case .mention, .reblog, .favourite, .poll, .status:
                                MastodonTabViewRouter.current.show(.timeline(.remoteThread(root: .notification(notificationID))), in: .notifications)
                            case .moderationWarning:
                                break
                            default:
                                assertionFailure()
                                break
                            }

                        } catch {
                            assertionFailure(error.localizedDescription)
                            return
                        }
                    }
                }   // end Task
            })
            .store(in: &disposeBag)
    }
}

extension SceneCoordinator {
    enum Transition {
        case show                           // push
        case showDetail                     // replace
        case modal(animated: Bool, completion: (() -> Void)? = nil)
        case popover(sourceView: UIView)
        case custom(transitioningDelegate: UIViewControllerTransitioningDelegate)
        case customPush(animated: Bool)
        case alertController(animated: Bool, completion: (() -> Void)? = nil)
        case activityViewControllerPresent(animated: Bool, completion: (() -> Void)? = nil)
        case formSheet([UISheetPresentationController.Detent]?)
        case none
    }

    enum Scene {
        // onboarding
        case welcome
        case mastodonPickServer(viewMode: MastodonPickServerViewModel)
        case mastodonRegister(viewModel: MastodonRegisterViewModel)
        case mastodonPrivacyPolicies(viewModel: PolicyViewModel)
        case mastodonServerRules(viewModel: MastodonServerRulesView.ViewModel)
        case mastodonConfirmEmail(viewModel: MastodonConfirmEmailViewModel)
        case mastodonResendEmail(viewModel: MastodonResendEmailViewModel)
        case mastodonWebView(viewModel: WebViewModel)
        case mastodonLogin(authenticationViewModel: AuthenticationViewModel, suggestedDomain: String?)

        // compose
        case compose(viewModel: ComposeViewModel)
        case editStatus(viewModel: ComposeViewModel)
        
        // thread
        case thread(Mastodon.Entity.Status, authenticatedUserDomain: String)
        case threadRemote(RemoteThreadType)
        
        // Hashtag Timeline
        case hashtagTimeline(Mastodon.Entity.Tag)

        // profile
        case profile(ProfileType)

        // setting
        case settings

        // Notifications
        case notificationPolicy(viewModel: NotificationPolicyViewModel)

        // report
        case report(viewModel: ReportViewModel)
        case reportServerRules(viewModel: ReportServerRulesViewModel)
        case reportStatus(viewModel: ReportStatusViewModel)
        case reportSupplementary(viewModel: ReportSupplementaryViewModel)
        case reportResult(viewModel: ReportResultViewModel)

        // suggestion account
        case suggestionAccount(viewModel: SuggestionAccountViewModel)
        
        // misc
        case alertController(alertController: UIAlertController)
        case activityViewController(activityViewController: UIActivityViewController, sourceView: UIView?, barButtonItem: UIBarButtonItem?)

        var isOnboarding: Bool {
            switch self {
                case .welcome,
                        .mastodonPickServer,
                        .mastodonRegister,
                        .mastodonLogin,
                        .mastodonServerRules,
                        .mastodonConfirmEmail,
                        .mastodonResendEmail:
                    return true
                default:
                    return false
            }
        }
    }   // end enum Scene { }
}

extension SceneCoordinator {
    
    @MainActor
    func setup() {
        
        let mainTabView = UIHostingController(rootView: MastodonMainTabView().environment(\.sceneCoordinator, self))
        sceneDelegate.window?.rootViewController = mainTabView
        self.rootViewController = mainTabView
        
        if authenticationBox == nil {                                                        // entry #1: welcome
            DispatchQueue.main.async {
                _ = self.present(
                    scene: .welcome,
                    from: mainTabView, // self.sceneDelegate.window?.rootViewController,
                    transition: .modal(animated: true, completion: nil)
                )
            }
        }
    }

    @MainActor
    @discardableResult
    func present(scene: Scene, from sender: UIViewController? = nil, transition: Transition) -> UIViewController? {
        guard let viewController = get(scene: scene, from: sender) else {
            return nil
        }
        guard let presentingViewController = sender ?? sceneDelegate.window?.rootViewController?.topMost else {
            return nil
        }

        switch transition {
        case .none:
            // do nothing
            break
        case .show:
            presentingViewController.show(viewController, sender: sender)
        case .showDetail:
            secondaryStackHashValues.insert(viewController.hashValue)
            let navigationController = AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
            presentingViewController.showDetailViewController(navigationController, sender: sender)

        case .modal(let animated, let completion):
            let modalNavigationController: UINavigationController = {
                if scene.isOnboarding {
                    return OnboardingNavigationController(rootViewController: viewController)
                } else {
                    return AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
                }
            }()
            modalNavigationController.modalPresentationCapturesStatusBarAppearance = true
            if let adaptivePresentationControllerDelegate = viewController as? UIAdaptivePresentationControllerDelegate {
                modalNavigationController.presentationController?.delegate = adaptivePresentationControllerDelegate
            }
            presentingViewController.present(modalNavigationController, animated: animated, completion: completion)
        case .popover(let sourceView):
            viewController.modalPresentationStyle = .popover
            viewController.popoverPresentationController?.sourceView = sourceView
            presentingViewController.present(viewController, animated: true, completion: nil)
        case .custom(let transitioningDelegate):
            viewController.modalPresentationStyle = .custom
            viewController.transitioningDelegate = transitioningDelegate
            viewController.modalPresentationCapturesStatusBarAppearance = true
            presentingViewController.present(viewController, animated: true, completion: nil)

        case .customPush(let animated):
            // set delegate in view controller
            assert(sender?.navigationController?.delegate != nil)
            sender?.navigationController?.pushViewController(viewController, animated: animated)

        case .alertController(let animated, let completion):
            viewController.modalPresentationCapturesStatusBarAppearance = true
            presentingViewController.present(viewController, animated: animated, completion: completion)

        case .activityViewControllerPresent(let animated, let completion):
            viewController.modalPresentationCapturesStatusBarAppearance = true
            presentingViewController.present(viewController, animated: animated, completion: completion)

        case .formSheet(let detents):
            viewController.modalPresentationStyle = .formSheet
            if let sheetPresentation = viewController.sheetPresentationController {
                sheetPresentation.detents = detents ?? [.medium(), .large()]
            }
            presentingViewController.present(viewController, animated: true)
        }

        return viewController
    }

    func switchToTabBar(tab: MastodonTabViewRouter.MastodonTab) {
        MastodonTabViewRouter.current.selectedTab = tab
    }
}

extension SceneCoordinator {
    
    func get(scene: Scene, from sender: UIViewController? = nil) -> UIViewController? {
        let viewController: UIViewController?
        switch scene {
        case .welcome:
            let _viewController = WelcomeViewController()
            viewController = _viewController
        case .mastodonPickServer(let viewModel):
            viewController = MastodonPickServerViewController(coordinator: self, viewModel: viewModel)
        case .mastodonRegister(let viewModel):
            let _viewController = MastodonRegisterViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonServerRules(let viewModel):
            let _viewController = MastodonServerRulesViewController(viewModel: viewModel)
            viewController = _viewController
        case .mastodonConfirmEmail(let viewModel):
            let _viewController = MastodonConfirmEmailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonLogin(let authenticationViewModel, let suggestedDomain):
            let loginViewController = MastodonLoginViewController(authenticationViewModel: authenticationViewModel,
                                                                  suggestedDomain: suggestedDomain)
            loginViewController.delegate = self

            viewController = loginViewController
        case .mastodonPrivacyPolicies(let viewModel):
            let policyViewController = PolicyTableViewController(coordinator: self, viewModel: viewModel)
            viewController = policyViewController
        case .mastodonResendEmail(let viewModel):
            let _viewController = MastodonResendEmailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonWebView(let viewModel):
            let _viewController = WebViewController(viewModel)
            viewController = _viewController
        case .compose(let viewModel):
            let _viewController = ComposeViewController(viewModel: viewModel)
            viewController = _viewController
        case .thread(let rootRecord, let domain):
            guard let rootPost = GenericMastodonPost.fromStatus(rootRecord, authenticatedDomain: domain) as? MastodonContentPost else { return nil }
            viewController = TimelineListViewController(.thread(root: rootPost), navigator: navigator)
        case .threadRemote(let entityType):
            viewController = TimelineListViewController(.remoteThread(root: entityType), navigator: navigator)
        case .hashtagTimeline(let tag):
            let _viewController = TimelineListViewController(.hashtag(tag), navigator: navigator)
            viewController = _viewController
        case .profile(let profileType):
            let _viewController: UIViewController =  {
                let needsNavigationStack = !(sender is UINavigationController) &&  sender?.navigationController == nil
                let controller = ProfileHostingViewController(navigationRouter: navigator)
                let account = MastodonAccount.fromEntity(profileType.accountToDisplay, authenticatedDomain: AuthenticationServiceProvider.shared.currentActiveUser.value?.domain ?? "")
                if account.globallyUniqueUserIdentifier == AuthenticationServiceProvider.shared.currentActiveUser.value?.globallyUniqueUserIdentifier {
                    controller.viewModel.set(account: account, relationship: .isMe, navigator: navigator)
                } else {
                    controller.viewModel.set(account: account, relationship: .isNotMe(nil), navigator: navigator)
                    
                    Task {
                        let relationshipFetchID = profileType.accountToDisplay.id
                        if let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value {
                            Task {
                                guard let relationship = try await APIService.shared.relationship(forAccountIds: [relationshipFetchID], authenticationBox: authBox).value.first else { return }
                                controller.viewModel.set(account: account, relationship: .isNotMe(MastodonAccount.RelationshipInfo(relationship, fetchedAt: .now)), navigator: navigator)
                            }
                        }
                    }
                }
                return controller
            }()
            viewController = _viewController
       
        case .report(let viewModel):
            viewController = ReportViewController(viewModel: viewModel)
        case .reportServerRules(let viewModel):
            let _viewController = ReportServerRulesViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .reportStatus(let viewModel):
            let _viewController = ReportStatusViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .reportSupplementary(let viewModel):
            let _viewController = ReportSupplementaryViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .reportResult(let viewModel):
            let _viewController = ReportResultViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .suggestionAccount(let viewModel):
            let _viewController = SuggestionAccountViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController


        case .alertController(let alertController):
            if let popoverPresentationController = alertController.popoverPresentationController {
                assert(
                    popoverPresentationController.sourceView != nil ||
                    popoverPresentationController.sourceRect != .zero ||
                    popoverPresentationController.barButtonItem != nil
                )
            }
            viewController = alertController
        case .activityViewController(let activityViewController, let sourceView, let barButtonItem):
            activityViewController.popoverPresentationController?.sourceView = sourceView
            activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
            viewController = activityViewController
        case .settings:
            guard let authenticationBox = self.authenticationBox else { return nil }
            
            let accountName = authenticationBox.authentication.username
            
            let settingsCoordinator = SettingsCoordinator(presentedOn: sender,
                                                          accountName: accountName,
                                                          appContext: AppContext.shared,
                                                          authenticationBox: authenticationBox,
                                                          sceneCoordinator: self
            )
            settingsCoordinator.delegate = self

            viewController = settingsCoordinator.settingsViewController
            childCoordinator = settingsCoordinator

        case .editStatus(let viewModel):
            let composeViewController = ComposeViewController(viewModel: viewModel)
            viewController = composeViewController
        case .notificationPolicy(let viewModel):
            viewController = NotificationPolicyViewController(viewModel)
        }

        return viewController
    }
}

//MARK: - Loading

public extension SceneCoordinator {

    @MainActor
    func showLoading() {
        showLoading(on: rootViewController)
    }

    @MainActor
    func showLoading(on viewController: UIViewController?) {
        guard let viewController else { return }
        
        /// Don't add HUD twice
        guard MBProgressHUD.forView(viewController.view) == nil else { return }
        
        MBProgressHUD.showAdded(to: viewController.view, animated: true)
    }

    @MainActor
    func hideLoading() {
        hideLoading(on: rootViewController)
    }

    @MainActor
    func hideLoading(on viewController: UIViewController?) {
        guard let viewController else { return }

        MBProgressHUD.hide(for: viewController.view, animated: true)
    }
}

//MARK: - MastodonLoginViewControllerDelegate

extension SceneCoordinator: MastodonLoginViewControllerDelegate {
    func backButtonPressed(_ viewController: MastodonLoginViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }
}

//MARK: - SettingsCoordinatorDelegate
extension SceneCoordinator: SettingsCoordinatorDelegate {
    func logout(_ user: MastodonAuthentication, presentingFrom viewController: UIViewController) {

        let preferredStyle: UIAlertController.Style

        if UIDevice.current.userInterfaceIdiom == .phone {
            preferredStyle = .actionSheet
        } else {
            preferredStyle = .alert
        }

        let alertController = UIAlertController(
            title: L10n.Common.Alerts.SignOut.title,
            message: L10n.Common.Alerts.SignOut.message,
            preferredStyle: preferredStyle
        )

        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
        let signOutAction = UIAlertAction(title: L10n.Common.Alerts.SignOut.confirm, style: .destructive) { [weak self] _ in
            guard let self else { return }

            NotificationService.shared.clearNotificationCountForActiveUser()

            Task { @MainActor in
                try await AuthenticationServiceProvider.shared.signOutMastodonUser(
                    authentication: user
                )
                self.setup()
                PersistenceManager.shared.removeAllCaches(forUser: user)
                try await BodegaPersistence.removeUser(user)
            }

        }

        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)

        (viewController.navigationController ?? viewController).present(alertController, animated: true)
    }

}

public extension UIViewController {
    var sceneCoordinator: SceneCoordinator? {
        guard let view = viewIfLoaded else { assert(false); return nil }
        if let coordinator = SceneCoordinator.coordinator(for: view) {
            return coordinator
        }
        if let navView = navigationController?.view {
            return SceneCoordinator.coordinator(for: navView)
        }
        return nil
    }
}
