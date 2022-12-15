//
//  DataSourceFacade+Status.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import CoreDataStack
import Alamofire
import AlamofireImage
import MastodonCore
import MastodonUI
import MastodonLocalization
import LinkPresentation
import UniformTypeIdentifiers

// Delete
extension DataSourceFacade {
    
    static func responseToDeleteStatus(
        dependency: NeedsDependency & AuthContextProvider,
        status: ManagedObjectRecord<Status>
    ) async throws {
        _ = try await dependency.context.apiService.deleteStatus(
            status: status,
            authenticationBox: dependency.authContext.mastodonAuthenticationBox
        )
    }
    
}

// Share
extension DataSourceFacade {
    
    @MainActor
    public static func responseToStatusShareAction(
        provider: DataSourceProvider,
        status: ManagedObjectRecord<Status>,
        button: UIButton
    ) async throws {
        let activityViewController = try await createActivityViewController(
            dependency: provider,
            status: status
        )
        _ = provider.coordinator.present(
            scene: .activityViewController(
                activityViewController: activityViewController,
                sourceView: button,
                barButtonItem: nil
            ),
            from: provider,
            transition: .activityViewControllerPresent(animated: true, completion: nil)
        )
    }
    
    private static func createActivityViewController(
        dependency: NeedsDependency,
        status: ManagedObjectRecord<Status>
    ) async throws -> UIActivityViewController {
        var activityItems: [Any] = try await dependency.context.managedObjectContext.perform {
            guard let status = status.object(in: dependency.context.managedObjectContext),
                  let url = URL(string: status.url ?? status.uri)
            else { return [] }
            return [
                URLActivityItemWithMetadata(url: url) { metadata in
                    metadata.title = "\(status.author.displayName) (@\(status.author.acctWithDomain))"
                    metadata.iconProvider = ImageProvider(
                        url: status.author.avatarImageURLWithFallback(domain: status.author.domain),
                        filter: ScaledToSizeFilter(size: CGSize.authorAvatarButtonSize)
                    ).itemProvider
                }
            ] as [Any]
        }
        var applicationActivities: [UIActivity] = [
            SafariActivity(sceneCoordinator: dependency.coordinator),     // open URL
        ]
        
        if let provider = dependency as? ShareActivityProvider {
            activityItems.append(contentsOf: provider.activities)
            applicationActivities.append(contentsOf: provider.applicationActivities)
        }
        
        let activityViewController = await UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return activityViewController
    }
}

// ActionToolBar
extension DataSourceFacade {
    @MainActor
    static func responseToActionToolbar(
        provider: DataSourceProvider & AuthContextProvider,
        status: ManagedObjectRecord<Status>,
        action: ActionToolbarContainer.Action,
        sender: UIButton
    ) async throws {
        let managedObjectContext = provider.context.managedObjectContext
        let _status: ManagedObjectRecord<Status>? = try? await managedObjectContext.perform {
            guard let object = status.object(in: managedObjectContext) else { return nil }
            let objectID = (object.reblog ?? object).objectID
            return .init(objectID: objectID)
        }
        guard let status = _status else {
            assertionFailure()
            return
        }

        switch action {
        case .reply:
            let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator.selectionChanged()
            
            let composeViewModel = ComposeViewModel(
                context: provider.context,
                authContext: provider.authContext,
                destination: .reply(parent: status)
            )
            _ = provider.coordinator.present(
                scene: .compose(viewModel: composeViewModel),
                from: provider,
                transition: .modal(animated: true, completion: nil)
            )
        case .reblog:
            try await DataSourceFacade.responseToStatusReblogAction(
                provider: provider,
                status: status
            )
        case .like:
            try await DataSourceFacade.responseToStatusFavoriteAction(
                provider: provider,
                status: status
            )
        case .bookmark:
            try await DataSourceFacade.responseToStatusBookmarkAction(
                provider: provider,
                status: status
            )
        case .share:
            try await DataSourceFacade.responseToStatusShareAction(
                provider: provider,
                status: status,
                button: sender
            )
        }   // end switch
    }   // end func

}

// menu
extension DataSourceFacade {
    
    struct MenuContext {
        let author: ManagedObjectRecord<MastodonUser>?
        let status: ManagedObjectRecord<Status>?
        let button: UIButton?
        let barButtonItem: UIBarButtonItem?
    }
    
    @MainActor
    static func responseToMenuAction(
        dependency: UIViewController & NeedsDependency & AuthContextProvider,
        action: MastodonMenu.Action,
        menuContext: MenuContext
    ) async throws {
        switch action {
            case .hideReblogs(let actionContext):
                let title = actionContext.showReblogs ? L10n.Scene.Profile.RelationshipActionAlert.ConfirmHideReblogs.title : L10n.Scene.Profile.RelationshipActionAlert.ConfirmShowReblogs.title
                let message = actionContext.showReblogs ? L10n.Scene.Profile.RelationshipActionAlert.ConfirmHideReblogs.message : L10n.Scene.Profile.RelationshipActionAlert.ConfirmShowReblogs.message

                let alertController = UIAlertController(
                    title: title,
                    message: message,
                    preferredStyle: .alert
                )

                let actionTitle = actionContext.showReblogs ? L10n.Common.Controls.Friendship.hideReblogs : L10n.Common.Controls.Friendship.showReblogs
                let showHideReblogsAction = UIAlertAction(
                    title: actionTitle,
                    style: .destructive
                ) { [weak dependency] _ in
                    guard let dependency else { return }

                    Task {
                        let managedObjectContext = dependency.context.managedObjectContext
                        let _user: ManagedObjectRecord<MastodonUser>? = try? await managedObjectContext.perform {
                            guard let user = menuContext.author?.object(in: managedObjectContext) else { return nil }
                            return ManagedObjectRecord<MastodonUser>(objectID: user.objectID)
                        }

                        guard let user = _user else { return }

                        try await DataSourceFacade.responseToShowHideReblogAction(
                            dependency: dependency,
                            user: user
                        )
                    }
                }

                alertController.addAction(showHideReblogsAction)

                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
                alertController.addAction(cancelAction)

                dependency.present(alertController, animated: true)
        case .muteUser(let actionContext):
            let alertController = UIAlertController(
                title: actionContext.isMuting ? L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title : L10n.Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.title,
                message: actionContext.isMuting ? L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(actionContext.name) : L10n.Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.message(actionContext.name),
                preferredStyle: .alert
            )
            let confirmAction = UIAlertAction(
                title: actionContext.isMuting ? L10n.Common.Controls.Friendship.unmute : L10n.Common.Controls.Friendship.mute,
                style: .destructive
            ) { [weak dependency] _ in
                guard let dependency = dependency else { return }
                Task {
                    let managedObjectContext = dependency.context.managedObjectContext
                    let _user: ManagedObjectRecord<MastodonUser>? = try? await managedObjectContext.perform {
                        guard let user = menuContext.author?.object(in: managedObjectContext) else { return nil }
                        return ManagedObjectRecord<MastodonUser>(objectID: user.objectID)
                    }
                    guard let user = _user else { return }
                    try await DataSourceFacade.responseToUserMuteAction(
                        dependency: dependency,
                        user: user
                    )
                }   // end Task
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true)
        case .blockUser(let actionContext):
            let alertController = UIAlertController(
                title: actionContext.isBlocking ? L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.title : L10n.Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.title,
                message: actionContext.isBlocking ? L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.message(actionContext.name) : L10n.Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.message(actionContext.name),
                preferredStyle: .alert
            )
            let confirmAction = UIAlertAction(
                title: actionContext.isBlocking ? L10n.Common.Controls.Friendship.unblock : L10n.Common.Controls.Friendship.block,
                style: .destructive
            ) { [weak dependency] _ in
                guard let dependency = dependency else { return }
                Task {
                    let managedObjectContext = dependency.context.managedObjectContext
                    let _user: ManagedObjectRecord<MastodonUser>? = try? await managedObjectContext.perform {
                        guard let user = menuContext.author?.object(in: managedObjectContext) else { return nil }
                        return ManagedObjectRecord<MastodonUser>(objectID: user.objectID)
                    }
                    guard let user = _user else { return }
                    try await DataSourceFacade.responseToUserBlockAction(
                        dependency: dependency,
                        user: user
                    )
                }   // end Task
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true)
        case .reportUser:
            Task {
                guard let user = menuContext.author else { return }
                
                let reportViewModel = ReportViewModel(
                    context: dependency.context,
                    authContext: dependency.authContext,
                    user: user,
                    status: menuContext.status
                )
                
                _ = dependency.coordinator.present(
                    scene: .report(viewModel: reportViewModel),
                    from: dependency,
                    transition: .modal(animated: true, completion: nil)
                )
            }   // end Task
                
        case .shareUser:
            guard let user = menuContext.author else {
                assertionFailure()
                return
            }
            let _activityViewController = try await DataSourceFacade.createActivityViewController(
                dependency: dependency,
                user: user
            )
            guard let activityViewController = _activityViewController else { return }
            _ = dependency.coordinator.present(
                scene: .activityViewController(
                    activityViewController: activityViewController,
                    sourceView: menuContext.button,
                    barButtonItem: menuContext.barButtonItem
                ),
                from: dependency,
                transition: .activityViewControllerPresent(animated: true, completion: nil)
            )
        case .bookmarkStatus:
            Task {
                guard let status = menuContext.status else {
                    assertionFailure()
                    return
                }
                try await DataSourceFacade.responseToStatusBookmarkAction(
                    provider: dependency,
                    status: status
                )
            }   // end Task
        case .shareStatus:
            Task {
                guard let status = menuContext.status else {
                    assertionFailure()
                    return
                }
                let activityViewController = try await DataSourceFacade.createActivityViewController(
                    dependency: dependency,
                    status: status
                )
                
                _ = dependency.coordinator.present(
                    scene: .activityViewController(
                        activityViewController: activityViewController,
                        sourceView: menuContext.button,
                        barButtonItem: menuContext.barButtonItem
                    ),
                    from: dependency,
                    transition: .activityViewControllerPresent(animated: true, completion: nil)
                )
            }   // end Task
        case .deleteStatus:
            let alertController = UIAlertController(
                title: L10n.Common.Alerts.DeletePost.title,
                message: L10n.Common.Alerts.DeletePost.message,
                preferredStyle: .alert
            )
            let confirmAction = UIAlertAction(
                title: L10n.Common.Controls.Actions.delete,
                style: .destructive
            ) { [weak dependency] _ in
                guard let dependency = dependency else { return }
                guard let status = menuContext.status else { return }
                Task {
                    try await DataSourceFacade.responseToDeleteStatus(
                        dependency: dependency,
                        status: status
                    )
                }   // end Task
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true)
            
        case .translateStatus:
            guard let status = menuContext.status else { return }
            do {
                try await DataSourceFacade.translateStatus(
                    provider: dependency,
                    status: status
                )
            } catch TranslationFailure.emptyOrInvalidResponse {
                let alertController = UIAlertController(title: L10n.Common.Alerts.TranslationFailed.title, message: L10n.Common.Alerts.TranslationFailed.message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: L10n.Common.Alerts.TranslationFailed.button, style: .default))
                dependency.present(alertController, animated: true)
            }
        }
    }   // end func
}

extension DataSourceFacade {
    
    static func responseToToggleSensitiveAction(
        dependency: NeedsDependency,
        status: ManagedObjectRecord<Status>
    ) async throws {
        try await dependency.context.managedObjectContext.perform {
            guard let _status = status.object(in: dependency.context.managedObjectContext) else { return }
            let status = _status.reblog ?? _status
            status.update(isSensitiveToggled: !status.isSensitiveToggled)
        }
    }
    
}

