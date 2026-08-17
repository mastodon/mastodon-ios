// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import WebKit
import MastodonSDK
import MastodonCore
import MastodonUI

enum MastodonNavigationDestination: Identifiable {
    case timeline(TimelineViewType)
    case profile(account: Mastodon.Entity.Account, relationship: MastodonAccount.Relationship?)
    case settings(SettingsDestinationType)
    case donations(DonationFlowDestination)
    case editProfile(profileViewModel: ProfileViewModel)
    case editProfileNavigation(destination: ProfileEditDestinationType)
    case share(activityItems: [Any])
    case legacy(scene: SceneCoordinator.Scene, transition: SceneCoordinator.Transition)
    
    var id: String { description }
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
    var navigationPath: [MastodonNavigationDestination] = []
    
    let uuid = UUID()
    
    // Action Sheets
    /// public set is allowed so that this can be easily bindable, but callers should avoid setting this directly, use presentModal(_,afterDeconflictionDelay:) or dismissCurrentModal() instead.
    var presentedSheet: MastodonSheet?
    var isPresentingSheet: Bool {
        get {
            presentedSheet != nil
        }
        set {
            if newValue == false {
                presentedSheet = nil
            }
        }
    }
    
    // Alerts
    var errorsWaitingToDisplay = [Error]()
    var activeAlert: MastodonPostMenuAction.AlertType? {
        didSet {
            displayNextErrorIfPossible()
        }
    }
    var alertIsPresented: Binding<Bool> {
        Binding(get: { [weak self] in
            self?.activeAlert != nil
        }, set: { [weak self] isPresenting in
            if !isPresenting {
                self?.activeAlert = nil
            }
        })
    }
    
    @ViewBuilder
    func destinationView(_ destination: MastodonNavigationDestination, sceneCoordinator: SceneCoordinator?) -> some View {
        switch destination {
        case .timeline(let timelineType):
            let asyncRefreshModel = AsyncRefreshViewModel()
            let timelineViewModel = timelineType.timelineViewModel(asyncRefreshViewModel: asyncRefreshModel, navigator: self)
            TimelineListView()
                .timelineEnvironment(timelineModel: timelineViewModel,
                                     contentConcealModel: timelineType.contentConcealModel,
                                     filter: timelineViewModel.timelineQueryFilter,
                                     asyncRefreshModel: asyncRefreshModel)
                .navigationTitle(timelineType.navigationTitle ?? "")

        case .profile(let account, let relationship):
            let viewModel = profileViewModel(account, relationship: relationship)
            ProfileView(wrapInSwiftUINavigationStack: false)
                .profileEnvironment(viewModel, nestedScroll: NestedScrollInteractionViewModel())
        case .editProfile(let profileViewModel):
            ProfileEditingView()
                .profileEditingEnvironment(profileViewModel)
            
        case .editProfileNavigation(let destination):
            ProfileEditingDestinationView(destinationType: destination)
                .profileEditingDestinationEnvironment(destination)
            
        case .settings:
            let _ = assertionFailure("SettingsNavigationView handles these")
            EmptyView()
            
        case .donations:
            let _ = assertionFailure("DonationFlowView handles these")
            EmptyView()
            
        case .legacy(let scene, _):
            if let sceneCoordinator {
                LegacyViewControllerWrapper(sceneCoordinator: sceneCoordinator, scene: scene)
            } else {
                Text("no scene coordinator")
            }
        case .share:
            EmptyView()  // legacy scenes should be presented using the SceneCoordinator instead
        }
    }
    
    @ViewBuilder func sheetContents(_ sheet: MastodonSheet) -> some View {
        switch sheet {
        case .timelineSheet:
            Text("Timeline must create timeline sheets itself")
        
        case .modalCompose(let model, let contentModel):
            let authBox = model.authenticationBox
            LegacyComposeViewControllerWrapper(authBox: authBox, composeViewModel: model, composeContentViewModel: contentModel)
        
        case .report(let model):
            LegacyReportFlowViewControllerWrapper(viewModel: model)
            
        case .welcome:
            LegacyWelcomeFlowWrapper()
        
        case .contentUrl(let url):
            SafariView(url: url.url)
            
        case .settings:
            if let authBox = AuthenticationObserver.shared.currentActiveUser {
                SettingsNavigationView(authBox: authBox)
            }
            
        case .profileEditingSheet(let profileEditType):
            ProfileEditingDestinationView(destinationType: profileEditType)
                .profileEditingDestinationEnvironment(profileEditType)
            
        case .notificationPolicy(let viewModel):
            NotificationPolicyView(viewModel: viewModel)
            
        case .makeDonation:
            DonationFlowView(campaign: nil, presentationSource: .menu)
        }
    }
    
    func push(_ destination: MastodonNavigationDestination) {
            switch destination {
            case .legacy(let scene, let transition):
                navigationPath.append(destination)
            case .editProfile(let profileViewModel):
                profileViewModel.editingStatus = .editing(hasChanges: false)
                fallthrough
            default:
                navigationPath.append(destination)
            }
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    public func presentSheet(_ sheet: MastodonSheet, afterDeconflictionDelay: Bool) {
        assert(presentedSheet == nil, "caller is responsible for dismissing any modals currently presented")
        if afterDeconflictionDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) { // without this delay, the modal presentation gets tangled up with any dismissing sheet
                self.presentedSheet = sheet
            }
        } else {
            self.presentedSheet = sheet
        }
    }
    
    public func openUrl(_ url: URL, afterDeconflictionDelay: Bool, forceInBrowser: Bool = false) {
        if forceInBrowser || UserDefaults.shared.preferredUsingDefaultBrowser {
            UIApplication.shared.open(url)
        } else {
            presentSheet(.contentUrl(ContentURL(url: url)), afterDeconflictionDelay: afterDeconflictionDelay)
        }
    }
    
    public func dismissCurrentModal() {
        if presentedSheet != nil {
            presentedSheet = nil
        }
        if activeAlert != nil {
            activeAlert = nil
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
                        do {
                            let relationship = try await APIService.shared.relationship(forAccountIds: [relationshipFetchID], authenticationBox: authBox)[relationshipFetchID]
                            guard let relationship else { return }
                            viewModel.updateRelationship(.isNotMe(MastodonAccount.RelationshipInfo(relationship, fetchedAt: .now)))
                        } catch {
                            didReceiveError(error)
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
        if activeAlert == nil {
            activeAlert = .error(error)
            _ = errorsWaitingToDisplay.removeFirst()
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
        case .editProfileNavigation(let destination):
            return "editProfile-\(destination.id)"
        case .settings(let type):
            return "settings-\(type)"
        case .donations(let type):
            return "donations-\(type)"
        case .share:
            return "share"
        case .legacy(let scene, let transition):
            return "LEGACY-\(scene)-\(transition)"
        }
    }
}

enum MastodonSheet: Identifiable {
    case timelineSheet(MastodonTimelineSheet)
    case profileEditingSheet(ProfileEditDestinationType)
    case modalCompose(ComposeViewModel, ComposeContentViewModel?)
    case settings
    case report(ReportViewModel)
    case welcome
    case contentUrl(ContentURL)
    case notificationPolicy(NotificationPolicyViewModel)
    case makeDonation
    
    var id: String {
        switch self {
        case .timelineSheet(let sheet):
            return sheet.id
        case .profileEditingSheet(let type):
            return type.id
        case .modalCompose:
            return "modal-compose"
        case .settings:
            return "settings"
        case .report(let model):
            return "report-\(model.account.id)"
        case .welcome:
            return "welcome"
        case .contentUrl(let url):
            return "url-\(url.url.absoluteString)"
        case .notificationPolicy:
            return "notification-policy"
        case .makeDonation:
            return "make-donation"
        }
    }
}

/// The init is fileprivate so that callers cannot present a .url sheet without going through the MastodonNavigationRouter's openURL method
struct ContentURL {
    let url: URL
    
    fileprivate init(url: URL) {
        self.url = url
    }
}
