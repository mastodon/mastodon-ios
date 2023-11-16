//
//  DataSourceFacade+Profile.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import UIKit
import MastodonCore
import MastodonSDK
import CoreDataStack

extension DataSourceFacade {
    
    static func coordinateToProfileScene(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: Mastodon.Entity.Status
    ) async {
        let _redirectRecord = DataSourceFacade.author(
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else {
            assertionFailure()
            return
        }
        await coordinateToProfileScene(
            provider: provider,
            user: redirectRecord
        )
    }
    
    @MainActor
    static func coordinateToProfileScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        user: Mastodon.Entity.Account
    ) async {
        let profileViewModel = ProfileViewModel(
            context: provider.context,
            authContext: provider.authContext,
            optionalMastodonUser: user
        )
        
        _ = provider.coordinator.present(
            scene: .profile(viewModel: profileViewModel),
            from: provider,
            transition: .show
        )
    }

    @MainActor
    static func coordinateToProfileScene(
        provider: ViewControllerWithDependencies & AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async {
        provider.coordinator.showLoading()
        
        guard let domain = account.domain else { return provider.coordinator.hideLoading() }
        
        Task {
            do {
                let user = try await provider.context.apiService.fetchUser(username: account.username,
                                                                           domain: domain,
                                                                           authenticationBox: provider.authContext.mastodonAuthenticationBox)
                provider.coordinator.hideLoading()
                
                await coordinateToProfileScene(provider: provider, user: user)

            } catch {
                provider.coordinator.hideLoading()
            }
        }
    }
}

extension DataSourceFacade {

    static func coordinateToProfileScene(
        provider: DataSourceProvider & AuthContextProvider,
        status: Mastodon.Entity.Status,
        mention: String,        // username,
        userInfo: [AnyHashable: Any]?
    ) async {
        guard
            let href = userInfo?["href"] as? String,
            let url = URL(string: href)
        else {
            return
        }
    
        let mentions = status.mentions
        
        guard let mention = mentions?.first(where: { $0.url == href }) else {
            _  = await provider.coordinator.present(
                scene: .safari(url: url),
                from: provider,
                transition: .safariPresent(animated: true, completion: nil)
            )
            return
        }
        
        let userID = mention.id
        let profileViewModel: ProfileViewModel = {
            // check if self
            guard userID != provider.authContext.mastodonAuthenticationBox.userID else {
                return MeProfileViewModel(context: provider.context, authContext: provider.authContext)
            }

            return RemoteProfileViewModel(context: provider.context, authContext: provider.authContext, userID: userID)
        }()
        
        _ = await provider.coordinator.present(
            scene: .profile(viewModel: profileViewModel),
            from: provider,
            transition: .show
        )
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
        user: Mastodon.Entity.Account
    ) async throws -> UIActivityViewController? {
        let managedObjectContext = dependency.context.managedObjectContext
        let activityItems: [Any] = try await managedObjectContext.perform {
            return user.activityItems
        }
        guard !activityItems.isEmpty else {
            assertionFailure()
            return nil
        }
        
        let activityViewController = await UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }
    
    static func createActivityViewControllerForMastodonUser(status: Mastodon.Entity.Status, dependency: NeedsDependency) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: status.activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }
}
