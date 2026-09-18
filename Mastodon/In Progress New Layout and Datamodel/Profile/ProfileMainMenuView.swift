// Copyright © 2026 Mastodon gGmbH. All rights reserved.
import SwiftUI
import MastodonCore
import MastodonLocalization
import MastodonUI

struct ProfileMainMenuView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(ProfileViewModel.self) private var myProfileViewModel: ProfileViewModel?
    @Environment(AuthenticationObserver.self) private var authenticationObserver
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                profileButtons
                Divider()
                contentButtons
                Divider()
                relationshipButtons
                Divider()
                alternateAccountButtons
                addAccountButton
                Divider()
                logOutActiveUserButton
            }
            .padding()
        }
    }
    
    // MARK: Profile buttons
    @ViewBuilder private var profileButtons: some View {
        if let currentActiveUser = authenticationObserver.currentActiveUser, let myProfileViewModel {
            // View Profile
            navigationRow("View Profile", icon: .avatar(currentActiveUser.cachedAccount?.avatarURL), navigatingTo: .myProfile(myProfileViewModel))
            // Edit Profile
            navigationRow("Edit Profile", icon: .image(Image(systemName: "person")), navigatingTo: .editProfile(profileViewModel: myProfileViewModel))
        }
        // Settings
        menuRow(L10n.Common.Controls.Actions.settings, icon: .image(Image(systemName: "gear"))) {
            navigator.presentSheet(.settings, afterDeconflictionDelay: false)
        }
    }
    
    // MARK: Content buttons
    @ViewBuilder private var contentButtons: some View {
        // Collections
        // Favourited Posts
        timelineRow(.myFavorites, image: Image(systemName: "heart"))
        // Saved Posts
        timelineRow(.myBookmarks, image: Image(systemName: "bookmark"))
    }
    
    // MARK: Relationship buttons
    @ViewBuilder private var relationshipButtons: some View {
        if let currentAcct = authenticationObserver.currentActiveUser?.cachedAccount {
            // Followers
            timelineRow(.followers(ofUserId: currentAcct.id), image: Image(systemName: "person.wave.2"))
            // Following
            timelineRow(.accountsFollowed(byUserId: currentAcct.id), image: Image(systemName: "person.2"))
            // Blocked Accounts
        }
    }
    
    @State private var isConfirmingLogOut: LogOutConfirmationType?
    @ViewBuilder private var logOutActiveUserButton: some View {
        menuRow(L10n.Scene.AccountList.logout, icon: .image(Image(systemName: "rectangle.portrait.and.arrow.forward")), role: .destructive) {
            isConfirmingLogOut = .logOutActiveAccount
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
            
            let account = authBox.cachedAccount
            menuRow(account.map{ "@\($0.acctWithDomain)" } ?? "", icon: .avatar(account?.avatarURL)) {
                authenticationObserver.switchTo(authBox)
            } accessory: {
                let unreadNotificationCount = UnreadNotificationCounts.shared.unreadCount(for: authBox)
                if unreadNotificationCount > 0 {
                    Text(unreadNotificationCount.formatted())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder private var addAccountButton: some View {
        menuRow(L10n.Scene.AccountList.addAccount, icon: .image(Image(systemName: "plus"))) {
            navigator.presentSheet(.welcome, afterDeconflictionDelay: false)
        }
    }
    
    private enum MenuRowIcon {
        case image(Image)
        case avatar(URL?)
    }
    private let avatarSize = AvatarSize.small
    private var iconSlotSize: CGFloat { avatarSize.rawValue }
    private var iconImageSize: CGFloat { iconSlotSize * 0.75 }
    @ViewBuilder private func rowIcon(_ icon: MenuRowIcon) -> some View {
        switch icon {
        case .image(let image):
            image
                .resizable()
                .scaledToFit()
                .frame(width: iconImageSize, height: iconImageSize)
        case .avatar(let url):
            AvatarView(style: .circular, size: avatarSize, avatarSource: .url(url))
        }
    }
    
    @ViewBuilder private func menuRow<Accessory: View>(_ title: String, icon: MenuRowIcon, role: ButtonRole? = nil, action: @escaping () -> Void, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) -> some View {
        Button(role: role, action: action) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text(title)
                        .font(.title3)
                } icon: {
                    rowIcon(icon)
                        .frame(width: iconSlotSize, height: iconSlotSize)
                }
                Spacer()
                accessory()
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal)
        .padding(.vertical, tinySpacing)
    }
    
    @ViewBuilder private func navigationRow(_ title: String, icon: MenuRowIcon, navigatingTo destination: MastodonNavigationDestination) -> some View {
        menuRow(title, icon: icon, role: nil) { navigator.push(destination) }
    }
    
    @ViewBuilder private func timelineRow(_ timelineType: MastodonTimelineType, image: Image) -> some View {
        navigationRow(timelineType.navigationTitle ?? "", icon: .image(image), navigatingTo: .timeline(timelineType))
    }
}
