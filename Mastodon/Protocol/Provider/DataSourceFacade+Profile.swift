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
        user: ManagedObjectRecord<MastodonUser>
    ) async {
        guard let user = user.object(in: provider.context.managedObjectContext) else {
            assertionFailure()
            return
        }
        
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
                
                if let user {
                    await coordinateToProfileScene(provider: provider, user: user.asRecord)
                }
            } catch {
                provider.coordinator.hideLoading()
            }
        }
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
            _  = provider.coordinator.present(
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

            let request = MastodonUser.sortedFetchRequest
            request.fetchLimit = 1
            request.predicate = MastodonUser.predicate(domain: domain, id: userID)
            let _user = provider.context.managedObjectContext.safeFetch(request).first

            if let user = _user {
                return ProfileViewModel(context: provider.context, authContext: provider.authContext, optionalMastodonUser: user)
            } else {
                return RemoteProfileViewModel(context: provider.context, authContext: provider.authContext, userID: userID)
            }
        }()
        
        _ = provider.coordinator.present(
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
        user: ManagedObjectRecord<MastodonUser>
    ) async throws -> UIActivityViewController? {
        let managedObjectContext = dependency.context.managedObjectContext
        let activityItems: [Any] = try await managedObjectContext.perform {
            guard let user = user.object(in: managedObjectContext) else { return [] }
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
    
    static func createActivityViewControllerForMastodonUser(status: Status, dependency: NeedsDependency) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: status.activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }
}
