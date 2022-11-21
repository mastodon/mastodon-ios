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
        provider: DataSourceProvider & AuthContextProvider,
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
        
        let href = userInfo?["href"] as? String
        guard let url = href.flatMap({ URL(string: $0) }) else { return }
    
        let managedObjectContext = provider.context.managedObjectContext
        let mentions = try? await managedObjectContext.perform {
            return status.object(in: managedObjectContext)?.mentions ?? []
        }
        
        guard let mention = mentions?.first(where: { $0.username == mention }) else {
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
    
//    @MainActor
//    static func createProfileActionMenu(
//        dependency: NeedsDependency,
//        user: ManagedObjectRecord<MastodonUser>
//    ) -> UIMenu {
//        var children: [UIMenuElement] = []
//        let name = mastodonUser.displayNameWithFallback
//
//        if let shareUser = shareUser {
//            let shareAction = UIAction(
//                title: L10n.Common.Controls.Actions.shareUser(name),
//                image: UIImage(systemName: "square.and.arrow.up"),
//                identifier: nil,
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            ) { [weak provider, weak sourceView, weak barButtonItem] _ in
//                guard let provider = provider else { return }
//                let activityViewController = createActivityViewControllerForMastodonUser(mastodonUser: shareUser, dependency: provider)
//                provider.coordinator.present(
//                    scene: .activityViewController(
//                        activityViewController: activityViewController,
//                        sourceView: sourceView,
//                        barButtonItem: barButtonItem
//                    ),
//                    from: provider,
//                    transition: .activityViewControllerPresent(animated: true, completion: nil)
//                )
//            }
//            children.append(shareAction)
//        }
//
//        if let shareStatus = shareStatus {
//            let shareAction = UIAction(
//                title: L10n.Common.Controls.Actions.sharePost,
//                image: UIImage(systemName: "square.and.arrow.up"),
//                identifier: nil,
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            ) { [weak provider, weak sourceView, weak barButtonItem] _ in
//                guard let provider = provider else { return }
//                let activityViewController = createActivityViewControllerForMastodonUser(status: shareStatus, dependency: provider)
//                provider.coordinator.present(
//                    scene: .activityViewController(
//                        activityViewController: activityViewController,
//                        sourceView: sourceView,
//                        barButtonItem: barButtonItem
//                    ),
//                    from: provider,
//                    transition: .activityViewControllerPresent(animated: true, completion: nil)
//                )
//            }
//            children.append(shareAction)
//        }
//
//        if !isMyself {
//            // mute
//            let muteAction = UIAction(
//                title: isMuting ? L10n.Common.Controls.Friendship.unmuteUser(name) : L10n.Common.Controls.Friendship.mute,
//                image: isMuting ? UIImage(systemName: "speaker") : UIImage(systemName: "speaker.slash"),
//                discoverabilityTitle: isMuting ? nil : L10n.Common.Controls.Friendship.muteUser(name),
//                attributes: isMuting ? [] : .destructive,
//                state: .off
//            ) { [weak provider, weak cell] _ in
//                guard let provider = provider else { return }
//
//                UserProviderFacade.toggleUserMuteRelationship(
//                    provider: provider,
//                    cell: cell
//                )
//                .sink { _ in
//                    // do nothing
//                } receiveValue: { _ in
//                    // do nothing
//                }
//                .store(in: &provider.context.disposeBag)
//            }
//            if isMuting {
//                children.append(muteAction)
//            } else {
//                let muteMenu = UIMenu(title: L10n.Common.Controls.Friendship.muteUser(name), image: UIImage(systemName: "speaker.slash"), options: [], children: [muteAction])
//                children.append(muteMenu)
//            }
//        }
//
//        if !isMyself {
//            // block
//            let blockAction = UIAction(
//                title: isBlocking ? L10n.Common.Controls.Friendship.unblockUser(name) : L10n.Common.Controls.Friendship.block,
//                image: isBlocking ? UIImage(systemName: "hand.raised.slash") : UIImage(systemName: "hand.raised"),
//                discoverabilityTitle: isBlocking ? nil : L10n.Common.Controls.Friendship.blockUser(name),
//                attributes: isBlocking ? [] : .destructive,
//                state: .off
//            ) { [weak provider, weak cell] _ in
//                guard let provider = provider else { return }
//
//                UserProviderFacade.toggleUserBlockRelationship(
//                    provider: provider,
//                    cell: cell
//                )
//                .sink { _ in
//                    // do nothing
//                } receiveValue: { _ in
//                    // do nothing
//                }
//                .store(in: &provider.context.disposeBag)
//            }
//            if isBlocking {
//                children.append(blockAction)
//            } else {
//                let blockMenu = UIMenu(title: L10n.Common.Controls.Friendship.blockUser(name), image: UIImage(systemName: "hand.raised"), options: [], children: [blockAction])
//                children.append(blockMenu)
//            }
//        }
//
//        if !isMyself {
//            let reportAction = UIAction(
//                title: L10n.Common.Controls.Actions.reportUser(name),
//                image: UIImage(systemName: "flag"),
//                identifier: nil,
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            ) { [weak provider] _ in
//                guard let provider = provider else { return }
//                guard let authenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
//                    return
//                }
//                let viewModel = ReportViewModel(
//                    context: provider.context,
//                    domain: authenticationBox.domain,
//                    user: mastodonUser,
//                    status: nil
//                )
//                provider.coordinator.present(
//                    scene: .report(viewModel: viewModel),
//                    from: provider,
//                    transition: .modal(animated: true, completion: nil)
//                )
//            }
//            children.append(reportAction)
//        }
//
//        if !isInSameDomain {
//            if isDomainBlocking {
//                let unblockDomainAction = UIAction(
//                    title: L10n.Common.Controls.Actions.unblockDomain(mastodonUser.domainFromAcct),
//                    image: UIImage(systemName: "nosign"),
//                    identifier: nil,
//                    discoverabilityTitle: nil,
//                    attributes: [],
//                    state: .off
//                ) { [weak provider, weak cell] _ in
//                    guard let provider = provider else { return }
//                    provider.context.blockDomainService.unblockDomain(userProvider: provider, cell: cell)
//                }
//                children.append(unblockDomainAction)
//            } else {
//                let blockDomainAction = UIAction(
//                    title: L10n.Common.Controls.Actions.blockDomain(mastodonUser.domainFromAcct),
//                    image: UIImage(systemName: "nosign"),
//                    identifier: nil,
//                    discoverabilityTitle: nil,
//                    attributes: [],
//                    state: .off
//                ) { [weak provider, weak cell] _ in
//                    guard let provider = provider else { return }
//
//                    let alertController = UIAlertController(title: L10n.Common.Alerts.BlockDomain.title(mastodonUser.domainFromAcct), message: nil, preferredStyle: .alert)
//                    let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .default) { _ in }
//                    alertController.addAction(cancelAction)
//                    let blockDomainAction = UIAlertAction(title: L10n.Common.Alerts.BlockDomain.blockEntireDomain, style: .destructive) { [weak provider, weak cell] _ in
//                        guard let provider = provider else { return }
//                        provider.context.blockDomainService.blockDomain(userProvider: provider, cell: cell)
//                    }
//                    alertController.addAction(blockDomainAction)
//                    provider.present(alertController, animated: true, completion: nil)
//                }
//                children.append(blockDomainAction)
//            }
//        }
//
//        if let status = shareStatus, isMyself {
//            let deleteAction = UIAction(
//                title: L10n.Common.Controls.Actions.delete,
//                image: UIImage(systemName: "delete.left"),
//                identifier: nil,
//                discoverabilityTitle: nil,
//                attributes: [.destructive],
//                state: .off
//            ) { [weak provider] _ in
//                guard let provider = provider else { return }
//
//                let alertController = UIAlertController(title: L10n.Common.Alerts.DeletePost.title, message: nil, preferredStyle: .alert)
//                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .default) { _ in }
//                alertController.addAction(cancelAction)
//                let deleteAction = UIAlertAction(title: L10n.Common.Alerts.DeletePost.delete, style: .destructive) { [weak provider] _ in
//                    guard let provider = provider else { return }
//                    guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
//                    provider.context.apiService.deleteStatus(
//                        domain: activeMastodonAuthenticationBox.domain,
//                        statusID: status.id,
//                        authorizationBox: activeMastodonAuthenticationBox
//                    )
//                    .sink { _ in
//                        // do nothing
//                    } receiveValue: { _ in
//                        // do nothing
//                    }
//                    .store(in: &provider.context.disposeBag)
//                }
//                alertController.addAction(deleteAction)
//                provider.present(alertController, animated: true, completion: nil)
//            }
//            children.append(deleteAction)
//        }
//        
//        return UIMenu(title: "", options: [], children: children)
//    }
    
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
