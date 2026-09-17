// Copyright © 2026 Mastodon gGmbH. All rights reserved.
import SwiftUI
import MastodonCore
import MastodonLocalization

struct ProfileMainMenuView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(MastodonTabViewRouter.self) private var tabViewRouter
    @Environment(ProfileViewModel.self) private var myProfileViewModel: ProfileViewModel?
    @Environment(AuthenticationObserver.self) private var authenticationObserver
    @State private var avatarIconRenderer = AvatarIconRenderer.shared
    
    var body: some View {
        @Bindable var navigator = navigator
        ScrollView {
            LazyVStack(alignment: .leading) {
                profileButtons
                Divider()
                alternateAccountButtons
                Divider()
                
                logOutActiveUserButton
                    .padding(.horizontal)
                    .padding(.vertical, tinySpacing)
            }
            .padding()
        }
        .sheet(isPresented: $navigator.isPresentingSheet) {
            if let presentedSheet = navigator.presentedSheet {
                navigator.sheetContents(presentedSheet)
            }
        }
    }

    // MARK: Profile buttons
    @ViewBuilder private var profileButtons: some View {
        viewProfileButton
            .padding(.horizontal)
        editProfileButton
            .padding(.horizontal)
        settingsButton
            .padding(.horizontal)
    }
    
    @ViewBuilder private var viewProfileButton: some View {
        if let currentActiveUser = authenticationObserver.currentActiveUser, let myProfileViewModel {
            Button {
                navigator.push(.myProfile(myProfileViewModel))
            } label: {
                Label {
                    Text("View Profile") // TODO: L10n
                } icon: {
                    avatarIconRenderer.prerenderedAccountAvatar(currentActiveUser.globallyUniqueUserIdentifier, style: .circular)
                }
            }
        }
    }
    
    @ViewBuilder private var editProfileButton: some View {
        if let myProfileViewModel {
            Button {
                navigator.push(.editProfile(profileViewModel: myProfileViewModel))
            } label: {
                Label {
                    Text("Edit Profile")
                } icon: {
                    Image(systemName: "person")
                }
            }
        }
    }
    
    @ViewBuilder private var settingsButton: some View {
        Button {
            navigator.presentSheet(.settings, afterDeconflictionDelay: false)
        } label: {
            Label {
                Text(L10n.Common.Controls.Actions.settings)
            } icon: {
                Image(systemName: "gear")
            }
        }
    }
    
    // MARK: Content buttons
    @ViewBuilder private var contentButtons: some View {
        // Collections
        // Favourited Posts
        // Saved Posts
    }
    
    // MARK: Relationship buttons
    @ViewBuilder private var relationshipButtons: some View {
        // Followers
        // Following
        // Blocked Accounts
    }
    
    @State private var isConfirmingLogOut: LogOutConfirmationType?
    @ViewBuilder private var logOutActiveUserButton: some View {
        Button(role: .destructive) {
            isConfirmingLogOut = .logOutActiveAccount
        } label: {
            Label(L10n.Scene.AccountList.logout, systemImage: "rectangle.portrait.and.arrow.forward")
        }
        .disabled(isConfirmingLogOut != nil)
        .confirmationDialog(isConfirmingLogOut?.title ?? "",
                            isPresented:
                                Binding<Bool>(
                                    get: { isConfirmingLogOut == .logOutActiveAccount },
                                    set: { newValue in
                                        if !newValue {
                                            isConfirmingLogOut = nil
                                        }
                                    }),
                            presenting: isConfirmingLogOut) { logOutType in
            Button(role: .destructive) {
                isConfirmingLogOut = nil
                guard let currentUser = authenticationObserver.currentActiveUser else { return }
                Task {
                    await AuthenticationServiceProvider.shared.signOutMastodonUser(authentication: currentUser.authentication)
                }
            } label: {
                Text(logOutType.buttonText)
            }
            Button(role: .cancel) {
                isConfirmingLogOut = nil
            } label: {
                Text(L10n.Common.Controls.Actions.cancel)
            }
        } message: { logOutType in
            Text(logOutType.message)
        }
        
    }
    
    @ViewBuilder private var alternateAccountButtons: some View {
        // List additional logged-in accounts, with their unread notification counts if non-zero
        ForEach(authenticationObserver.allLoggedInUsers.filter({ $0.globallyUniqueUserIdentifier != authenticationObserver.currentActiveUser?.globallyUniqueUserIdentifier }), id: \.self.globallyUniqueUserIdentifier) { authBox in
            Button {
                authenticationObserver.switchTo(authBox)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Label {
                        if let handle = authBox.cachedAccount?.acctWithDomain {
                            Text("@\(handle)")
                        } else {
                            Text(authBox.cachedAccount?.displayName ?? "")
                        }
                    } icon: {
                        avatarIconRenderer.prerenderedAccountAvatar(authBox.globallyUniqueUserIdentifier, style: .circular) ?? Image(systemName: "app.dashed")
                    }
                    
                    let unreadNotificationCount = UnreadNotificationCounts.shared.unreadCount(for: authBox)
                    Spacer()
                    if unreadNotificationCount > 0 {
                        Text(unreadNotificationCount.formatted())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, tinySpacing)
            }
        }
        
        // Offer adding another account
        Button {
            tabViewRouter.selectedTab = .home
            tabViewRouter.navigationRouter(forTab: .home).presentSheet(.welcome, afterDeconflictionDelay: true)
        } label: {
            Label {
                Text(L10n.Scene.AccountList.addAccount)
            } icon: {
                Image(systemName: "plus")
            }
            .padding(.horizontal)
            .padding(.vertical, tinySpacing)
        }
    }
}
