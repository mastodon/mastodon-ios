//
//  UserProviderFacade.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

enum UserProviderFacade { }

extension UserProviderFacade {
    
    static func toggleUserFollowRelationship(
        provider: UserProvider
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }

        return _toggleUserFollowRelationship(
            context: provider.context,
            activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
            mastodonUser: provider.mastodonUser().eraseToAnyPublisher()
        )
    }
    
    private static func _toggleUserFollowRelationship(
        context: AppContext,
        activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        mastodonUser: AnyPublisher<MastodonUser?, Never>
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                
                return context.apiService.toggleFollow(
                    for: mastodonUser,
                    activeMastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

extension UserProviderFacade {
    
    static func toggleUserBlockRelationship(
        provider: UserProvider
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }

        return _toggleUserBlockRelationship(
            context: provider.context,
            activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
            mastodonUser: provider.mastodonUser().eraseToAnyPublisher()
        )
    }
    
    private static func _toggleUserBlockRelationship(
        context: AppContext,
        activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        mastodonUser: AnyPublisher<MastodonUser?, Never>
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                
                return context.apiService.toggleBlock(
                    for: mastodonUser,
                    activeMastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

extension UserProviderFacade {
    
    static func toggleUserMuteRelationship(
        provider: UserProvider
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }

        return _toggleUserMuteRelationship(
            context: provider.context,
            activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
            mastodonUser: provider.mastodonUser().eraseToAnyPublisher()
        )
    }
    
    private static func _toggleUserMuteRelationship(
        context: AppContext,
        activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        mastodonUser: AnyPublisher<MastodonUser?, Never>
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                
                return context.apiService.toggleMute(
                    for: mastodonUser,
                    activeMastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

extension UserProviderFacade {
    
    static func createProfileActionMenu(
        for mastodonUser: MastodonUser,
        isMuting: Bool,
        isBlocking: Bool,
        needsShareAction: Bool,
        provider: UserProvider,
        sourceView: UIView?,
        barButtonItem: UIBarButtonItem?
    ) -> UIMenu {
        var children: [UIMenuElement] = []
        let name = mastodonUser.displayNameWithFallback
        
        // mute
        let muteAction = UIAction(
            title: isMuting ? L10n.Common.Controls.Firendship.unmuteUser(name) : L10n.Common.Controls.Firendship.mute,
            image: isMuting ? UIImage(systemName: "speaker") : UIImage(systemName: "speaker.slash"),
            discoverabilityTitle: isMuting ? nil : L10n.Common.Controls.Firendship.muteUser(name),
            attributes: isMuting ? [] : .destructive,
            state: .off
        ) { [weak provider] _ in
            guard let provider = provider else { return }

            UserProviderFacade.toggleUserMuteRelationship(
                provider: provider
            )
            .sink { _ in
                // do nothing
            } receiveValue: { _ in
                // do nothing
            }
            .store(in: &provider.context.disposeBag)
        }
        if isMuting {
            children.append(muteAction)
        } else {
            let muteMenu = UIMenu(title: L10n.Common.Controls.Firendship.muteUser(name), image: UIImage(systemName: "speaker.slash"), options: [], children: [muteAction])
            children.append(muteMenu)
        }
        
        // block
        let blockAction = UIAction(
            title: isBlocking ? L10n.Common.Controls.Firendship.unblockUser(name) : L10n.Common.Controls.Firendship.block,
            image: isBlocking ? UIImage(systemName: "hand.raised.slash") : UIImage(systemName: "hand.raised"),
            discoverabilityTitle: isBlocking ? nil : L10n.Common.Controls.Firendship.blockUser(name),
            attributes: isBlocking ? [] : .destructive,
            state: .off
        ) { [weak provider] _ in
            guard let provider = provider else { return }

            UserProviderFacade.toggleUserBlockRelationship(
                provider: provider
            )
            .sink { _ in
                // do nothing
            } receiveValue: { _ in
                // do nothing
            }
            .store(in: &provider.context.disposeBag)
        }
        if isBlocking {
            children.append(blockAction)
        } else {
            let blockMenu = UIMenu(title: L10n.Common.Controls.Firendship.blockUser(name), image: UIImage(systemName: "hand.raised"), options: [], children: [blockAction])
            children.append(blockMenu)
        }
        
        if needsShareAction {
            let shareAction = UIAction(title: L10n.Common.Controls.Actions.shareUser(name), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak provider] _ in
                guard let provider = provider else { return }
                let activityViewController = createActivityViewControllerForMastodonUser(mastodonUser: mastodonUser, dependency: provider)
                provider.coordinator.present(
                    scene: .activityViewController(
                        activityViewController: activityViewController,
                        sourceView: sourceView,
                        barButtonItem: barButtonItem
                    ),
                    from: provider,
                    transition: .activityViewControllerPresent(animated: true, completion: nil)
                )
            }
            children.append(shareAction)
        }
        
        return UIMenu(title: "", options: [], children: children)
    }
    
    static func createActivityViewControllerForMastodonUser(mastodonUser: MastodonUser, dependency: NeedsDependency) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: mastodonUser.activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }

}
