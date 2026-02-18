// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

enum MastodonNavigationDestination {
    case editProfile(profileViewModel: ProfileViewModel, editingViewModel: ProfileEditingViewModel)
    case familiarFollowers(account: MastodonAccount, listViewModel: TimelineListViewModel)
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
    var navigationController: UINavigationController?
    
    @ViewBuilder
    func destinationView(_ destination: MastodonNavigationDestination) -> some View {
        switch destination {
        case .editProfile(let profileViewModel, let editingViewModel):
            ProfileEditingView()
                .environment(profileViewModel)
                .environment(editingViewModel)
        case .familiarFollowers(_, let listViewModel):
            TimelineListView()
                .environment(listViewModel)
                .environment(TimelineQueryFilter(.unfilterable))
                .environment(AsyncRefreshViewModel())
        }
    }
    
    func navigate(to destination: MastodonNavigationDestination) {
        if let navigationController {
            switch destination {
            case .editProfile(let profileViewModel, _):
                profileViewModel.editingStatus = .editing(hasChanges: false)
                let editViewController = ProfileEditHostingViewController(viewModel: profileViewModel)
                navigationController.pushViewController(editViewController, animated: true)
            case .familiarFollowers(let account, let listViewModel):
                let familiarFollowersController = TimelineListViewController(.familiarFollowers(account, listViewModel))
                navigationController.pushViewController(familiarFollowersController, animated: true)
            }
        } else {
            navigationPath.append(destination)
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
        case .editProfile:
            return "editProfile"
        case .familiarFollowers(let account, _):
            return "familiarFollowersOf\(account.globallyUniqueUserIdentifier)"
        }
    }
}
