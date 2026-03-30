// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore

enum MastodonNavigationDestination {
    case timeline(TimelineViewType)
    case profile(account: Mastodon.Entity.Account, relationship: MastodonAccount.Relationship?)
    case editProfile(profileViewModel: ProfileViewModel, editingViewModel: ProfileEditingViewModel)
    case editProfileInternalNavigation(ProfileEditScreenType)
    case share(activityItems: [Any])
    case legacy(scene: SceneCoordinator.Scene, transition: SceneCoordinator.Transition)
}

/// Views requiring navigation support should include this class as an @Environment var:
///  @Environment(MastodonNavigationRouter.self) private var router
/// And then bind it in the body like so:
/// var body: some View {
///    @Bindable var router = router
///     <...view content>
/// }
/// See https://azamsharp.com/2024/07/29/navigation-patterns-in-swiftui.html, the section titled "Global Routing in SwiftUI"
@MainActor
@Observable class MastodonNavigationRouter {
    enum NavigationType {
        case uiKit(UIViewController?)
        case swiftUI(legacyPresenter: UIViewController?)
    }
    var navigationType: NavigationType
    
    var navigationPath: [MastodonNavigationDestination] = []
    
    // Action Sheets
    var presentedActionSheet: MastodonTimelineSheet?
    
    // Alerts
    var errorsWaitingToDisplay = [Error]()
    var activeAlert: MastodonPostMenuAction.AlertType = .noAlert {
        didSet {
            displayNextErrorIfPossible()
        }
    }
    var alertIsPresented: Binding<Bool> {
        Binding(get: { [weak self] in
            return self?.activeAlert.shouldBePresented ?? false
        }, set: { [weak self] isPresenting in
            if !isPresenting {
                self?.activeAlert = .noAlert
            }
        })
    }
    
    init(navigationType: NavigationType) {
        self.navigationType = navigationType
    }
    
    @ViewBuilder
    func destinationView(_ destination: MastodonNavigationDestination) -> some View {
        switch destination {
        case .timeline(let timelineType):
            let asyncRefreshModel = AsyncRefreshViewModel()
            let timelineViewModel = timelineType.timelineViewModel(asyncRefreshViewModel: asyncRefreshModel, navigator: self)
            let queryFilter = timelineViewModel.timelineQueryFilter
            TimelineListView()
                .environment(timelineViewModel)
                .environment(queryFilter)
                .environment(asyncRefreshModel)
                .navigationTitle(timelineType.navigationTitle ?? "")
            
        case .profile(let account, let relationship):
            let viewModel = profileViewModel(account, relationship: relationship)
            ProfileView(wrapInSwiftUINavigationStack: false)
                .environment(viewModel)
                .environment(viewModel.relationshipViewModel)
                .environment(NestedScrollInteractionViewModel())
        case .editProfile(let profileViewModel, let editingViewModel):
            ProfileEditingView()
                .environment(profileViewModel)
                .environment(profileViewModel.relationshipViewModel)
                .environment(editingViewModel)
            
        case .editProfileInternalNavigation(let screen):
            ProfileEditingScreen(screenType: screen)
                .environment(screen.profileViewModel)
                .environment(screen.editingViewModel)
            
        case .legacy, .share:
            EmptyView()  // legacy scenes should be presented using the SceneCoordinator instead
        }
    }
    
    private func destinationViewController(_ destination: MastodonNavigationDestination) -> UIViewController? {
        let newNavigator = MastodonNavigationRouter(navigationType: .uiKit(nil))
        let newController: UIViewController? = {
            switch destination {
            case .timeline(let timelineViewType):
                return TimelineListViewController(timelineViewType, navigator: newNavigator)
                
            case .profile(let account, let relationship):
                let profile = ProfileHostingViewController(navigationRouter: newNavigator)
                setUpProfileViewModel(profile.viewModel, account: account, relationship: relationship)
                return profile
            case .editProfile(let profileViewModel, _):
                profileViewModel.editingStatus = .editing(hasChanges: false)
                return ProfileEditHostingViewController(viewModel: profileViewModel, navigator: newNavigator)
                
            case .editProfileInternalNavigation(let screen):
                return nil
                
            case .legacy, .share:
                return nil
            }
        }()
        newNavigator.navigationType = .uiKit(newController)
        return newController
    }
    
    func push(_ destination: MastodonNavigationDestination) {
        switch navigationType {
        case .uiKit(let uiViewController):
            if let navigationController = (uiViewController as? UINavigationController) ?? uiViewController?.navigationController, let pushedController = destinationViewController(destination) {
                navigationController.pushViewController(pushedController, animated: true)
            } else {
                switch destination {
                case .legacy(let scene, let transition):
                    uiViewController?.sceneCoordinator?.present(scene: scene, from: uiViewController, transition: transition)
                default:
                    assertionFailure("non-legacy destinations should have been handled above")
                }
            }
        case .swiftUI(let legacyPresenter):
            switch destination {
            case .legacy(let scene, let transition):
                legacyPresenter?.sceneCoordinator?.present(scene: scene, from: legacyPresenter, transition: transition)
            case .editProfile(let profileViewModel, _):
                profileViewModel.editingStatus = .editing(hasChanges: false)
                fallthrough
            default:
                navigationPath.append(destination)
            }
        }
    }
    
    func presentModal(_ destination: MastodonNavigationDestination) {
        switch destination {
        case .legacy(let scene, let transition):
            switch navigationType {
            case .uiKit(let presenter), .swiftUI(let presenter):
                if presentedActionSheet != nil {
                    presentedActionSheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) { // without this delay, the modal presentation gets tangled up with the dismissing sheet
                        presenter?.sceneCoordinator?.present(scene: scene, from: presenter, transition: transition)
                    }
                } else {
                    presenter?.sceneCoordinator?.present(scene: scene, from: presenter, transition: transition)
                }
            }
        case .share(let activityItems):
            let sceneCoordinator: SceneCoordinator? = {
                switch navigationType {
                case .uiKit(let presenter), .swiftUI(let presenter):
                    presenter?.sceneCoordinator
                }
            }()
            let activityViewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: [SafariActivity(sceneCoordinator: sceneCoordinator)]
            )
            self.presentModal(.legacy(scene: .activityViewController(activityViewController: activityViewController, sourceView: nil, barButtonItem: nil), transition: .activityViewControllerPresent(animated: true, completion: nil)))

        default:
            assertionFailure()
            break
        }
    }
    
    private func profileScene(accountEntity: Mastodon.Entity.Account, relationship: MastodonAccount.Relationship?) -> ProfileType? {
        if relationship?.refersToSameAccount(as: .isMe) == true {
            return .me(accountEntity)
        } else {
            guard let me = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount else { return nil }
            return .notMe(me: me, displayAccount: accountEntity, relationship: relationship?.info?._legacyEntity)
        }
    }
    
    private func profileViewModel(_ account: Mastodon.Entity.Account, relationship: MastodonAccount.Relationship?) -> ProfileViewModel {
        let newModel = ProfileViewModel()
        setUpProfileViewModel(newModel, account: account, relationship: relationship)
        return newModel
    }
    
    private func setUpProfileViewModel(_ viewModel: ProfileViewModel, account: Mastodon.Entity.Account, relationship: MastodonAccount.Relationship?) {
        let account = MastodonAccount.fromEntity(account, authenticatedDomain: AuthenticationServiceProvider.shared.currentActiveUser.value?.domain ?? "")
        if account.globallyUniqueUserIdentifier == AuthenticationServiceProvider.shared.currentActiveUser.value?.globallyUniqueUserIdentifier {
            viewModel.set(account: account, relationship: .isMe, navigator: self)
        } else {
            viewModel.set(account: account, relationship: .isNotMe(relationship?.info), navigator: self)
            
            if relationship?.info == nil {
                Task {
                    let relationshipFetchID = account.id
                    if let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value {
                        Task {
                            guard let relationship = try await APIService.shared.relationship(forAccountIds: [relationshipFetchID], authenticationBox: authBox).value.first else { return }
                            viewModel.set(account: account, relationship: .isNotMe(MastodonAccount.RelationshipInfo(relationship, fetchedAt: .now)), navigator: self)
                        }
                    }
                }
            }
        }
    }
}

extension MastodonNavigationRouter {
    func didReceiveError(_ error: Error) {
        if errorsWaitingToDisplay.count < 3 {
            errorsWaitingToDisplay.append(error)
        }
        displayNextErrorIfPossible()
    }
    
    func displayNextErrorIfPossible() {
        guard let error = errorsWaitingToDisplay.first else { return }
        switch activeAlert {
        case .noAlert:
            activeAlert = .error(error)
            _ = errorsWaitingToDisplay.removeFirst()
        default:
            return
        }
    }
}

extension MastodonNavigationDestination: Hashable {
    static func == (lhs: MastodonNavigationDestination, rhs: MastodonNavigationDestination) -> Bool {
        return lhs.description == rhs.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
    var description: String {
        switch self {
        case .timeline(let type):
            return "timeline(\(type))"
        case .profile(let account, let relationship):
            let isMeString = {
                guard let isMyAccount = relationship?.refersToSameAccount(as: .isMe) else { return "ME_UNKNOWN" }
                return isMyAccount ? "isMe" : "notMe"
            }()
            return "profile(\(account.acctWithDomain)-\(isMeString))"
        case .editProfile:
            return "editProfile"
        case .editProfileInternalNavigation(let screen):
            return "editProfile-\(screen.id)"
        case .share:
            return "share"
        case .legacy(let scene, let transition):
            return "LEGACY-\(scene)-\(transition)"
        }
    }
}
