//
//  DataSourceFacade+Profile.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import UIKit
import CoreDataStack
import MastodonCore

extension DataSourceFacade {
    
    static func coordinateToProfileScene(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: ManagedObjectRecord<Status>
    ) async {
        let _redirectRecord = await DataSourceFacade.author(
            managedObjectContext: provider.context.managedObjectContext,
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
        provider: NeedsDependency & UIViewController & AuthContextProvider,
        user: ManagedObjectRecord<MastodonUser>
    ) async {
        guard let user = user.object(in: provider.context.managedObjectContext) else {
            assertionFailure()
            return
        }
        
        let profileViewModel = CachedProfileViewModel(
            context: provider.context,
            authContext: provider.authContext,
            mastodonUser: user
        )
        
        _ = provider.coordinator.present(
            scene: .profile(viewModel: profileViewModel),
            from: provider,
            transition: .show
        )
    }
    
}

extension DataSourceFacade {

    static func coordinateToProfileScene(
        provider: DataSourceProvider & AuthContextProvider,
        status: ManagedObjectRecord<Status>,
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
    
        let managedObjectContext = provider.context.managedObjectContext
        let mentions = try? await managedObjectContext.perform {
            return status.object(in: managedObjectContext)?.mentions ?? []
        }
        
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

            let request = MastodonUser.sortedFetchRequest
            request.fetchLimit = 1
            request.predicate = MastodonUser.predicate(domain: domain, id: userID)
            let _user = provider.context.managedObjectContext.safeFetch(request).first

            if let user = _user {
                return CachedProfileViewModel(context: provider.context, authContext: provider.authContext, mastodonUser: user)
            } else {
                return RemoteProfileViewModel(context: provider.context, authContext: provider.authContext, userID: userID)
            }
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
