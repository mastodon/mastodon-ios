//
//  DataSourceFacade+Profile.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import UIKit
import CoreDataStack
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    
    @MainActor
    static func coordinateToProfileScene(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: MastodonStatus
    ) async {
        let acct: String
        switch target {
        case .status:
            acct = status.reblog?.entity.account.acct ?? status.entity.account.acct
        case .reblog:
            acct = status.entity.account.acct
        }
        
        provider.coordinator.showLoading()
        
        let _redirectRecord = try? await Mastodon.API.Account.lookupAccount(
            session: .shared,
            domain: provider.authContext.mastodonAuthenticationBox.domain,
            query: .init(acct: acct),
            authorization: provider.authContext.mastodonAuthenticationBox.userAuthorization
        ).singleOutput().value
                
        guard let redirectRecord = _redirectRecord else {
            assertionFailure()
            provider.coordinator.hideLoading()
            return
        }
        await coordinateToProfileScene(
            provider: provider,
            account: redirectRecord
        )
    }

    @MainActor
    static func coordinateToProfileScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        username: String,
        domain: String
    ) async {
        provider.coordinator.showLoading()

        Task {
            do {
                guard let account = try await provider.context.apiService.fetchUser(username: username,
                                                                                    domain: domain,
                                                                                    authenticationBox: provider.authContext.mastodonAuthenticationBox) else {
                    return provider.coordinator.hideLoading()
                }

                provider.coordinator.hideLoading()

                await coordinateToProfileScene(provider: provider, account: account)
            } catch {
                provider.coordinator.hideLoading()
            }
        }
    }

    @MainActor
    static func coordinateToProfileScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        domain: String,
        accountID: String
    ) async {
        provider.coordinator.showLoading()

        Task {
            do {
                let account = try await provider.context.apiService.accountInfo(
                    domain: domain,
                    userID: accountID,
                    authorization: provider.authContext.mastodonAuthenticationBox.userAuthorization
                ).value

                provider.coordinator.hideLoading()

                await coordinateToProfileScene(provider: provider, account: account)
            } catch {
                provider.coordinator.hideLoading()
            }
        }
    }

    @MainActor
    static func coordinateToProfileScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        account: Mastodon.Entity.Account
    ) {

        let profileViewModel = ProfileViewModel(
            context: provider.context,
            authContext: provider.authContext,
            account: account
        )
        
        _ = provider.coordinator.present(
            scene: .profile(viewModel: profileViewModel),
            from: provider,
            transition: .show
        )
    }
}

extension DataSourceFacade {

    @MainActor
    static func coordinateToProfileScene(
        provider: DataSourceProvider & AuthContextProvider,
        status: MastodonStatus,
        mention: String,        // username,
        userInfo: [AnyHashable: Any]?
    ) async {
        let domain = provider.authContext.mastodonAuthenticationBox.domain
        
        guard
            let href = userInfo?["href"] as? String,
            let url = URL(string: href)
        else {
            return
        }
        let mentions = status.entity.mentions ?? []

        guard let mention = mentions.first(where: { $0.url == href }) else {
            _ = provider.coordinator.present(
                scene: .safari(url: url),
                from: provider,
                transition: .safariPresent(animated: true, completion: nil)
            )

            return
        }

        await DataSourceFacade.coordinateToProfileScene(provider: provider, domain: domain, accountID: mention.id)
    }

}

extension DataSourceFacade {
    
    struct ProfileActionMenuContext {
        let isMuting: Bool
        let isBlocking: Bool
        let isMyself: Bool
        
        let cell: UITableViewCell?
        let sourceView: UIView?
        let barButtonItem: UIBarButtonItem?
    }
    
    static func createActivityViewController(
        dependency: NeedsDependency,
        account: Mastodon.Entity.Account
    ) -> UIActivityViewController {

        let activityViewController = UIActivityViewController(
            activityItems: [account.url],
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }
    
    static func createActivityViewControllerForMastodonUser(status: Status, dependency: NeedsDependency) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: status.activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }
}
