//
//  DataSourceFacade+Status.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import CoreDataStack
import MastodonUI
import MastodonLocalization

extension DataSourceFacade {
    
    static func responseToDeleteStatus(
        dependency: NeedsDependency,
        status: ManagedObjectRecord<Status>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        _ = try await dependency.context.apiService.deleteStatus(
            status: status,
            authenticationBox: authenticationBox
        )
    }
    
}

extension DataSourceFacade {
    
    @MainActor
    public static func responseToStatusShareAction(
        provider: DataSourceProvider,
        status: ManagedObjectRecord<Status>,
        button: UIButton
    ) async throws {
        let activityViewController = try await createActivityViewController(
            provider: provider,
            status: status
        )
        provider.coordinator.present(
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
        provider: DataSourceProvider,
        status: ManagedObjectRecord<Status>
    ) async throws -> UIActivityViewController {
        var activityItems: [Any] = try await provider.context.managedObjectContext.perform {
            guard let status = status.object(in: provider.context.managedObjectContext) else { return [] }
            let url = status.url ?? status.uri
            return [URL(string: url)].compactMap { $0 } as [Any]
        }
        var applicationActivities: [UIActivity] = [
            SafariActivity(sceneCoordinator: provider.coordinator),     // open URL
        ]
        
        if let provider = provider as? ShareActivityProvider {
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

extension DataSourceFacade {
    @MainActor
    static func responseToActionToolbar(
        provider: DataSourceProvider,
        status: ManagedObjectRecord<Status>,
        action: ActionToolbarContainer.Action,
        authenticationBox: MastodonAuthenticationBox,
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
            guard let authenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
            let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator.selectionChanged()
            
            let composeViewModel = ComposeViewModel(
                context: provider.context,
                composeKind: .reply(status: status),
                authenticationBox: authenticationBox
            )
            provider.coordinator.present(
                scene: .compose(viewModel: composeViewModel),
                from: provider,
                transition: .modal(animated: true, completion: nil)
            )
        case .reblog:
            try await DataSourceFacade.responseToStatusReblogAction(
                provider: provider,
                status: status,
                authenticationBox: authenticationBox
            )
        case .like:
            try await DataSourceFacade.responseToStatusFavoriteAction(
                provider: provider,
                status: status,
                authenticationBox: authenticationBox
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

extension DataSourceFacade {
    
    struct MenuContext {
        let author: ManagedObjectRecord<MastodonUser>?
        let status: ManagedObjectRecord<Status>?
        let button: UIButton?
        let barButtonItem: UIBarButtonItem?
    }
    
    @MainActor
    static func responseToMenuAction(
        dependency: NeedsDependency & UIViewController,
        action: MastodonMenu.Action,
        menuContext: MenuContext,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        switch action {
        case .muteUser(let actionContext):
            let alertController = UIAlertController(
                title: actionContext.isMuting ? "Unmute Account" : "Mute Account",
                message: actionContext.isMuting ? "Confirm to unmute \(actionContext.name)" : "Confirm to mute \(actionContext.name)",
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
                        user: user,
                        authenticationBox: authenticationBox
                    )
                }   // end Task
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true, completion: nil)
        case .blockUser(let actionContext):
            let alertController = UIAlertController(
                title: actionContext.isBlocking ? "Unblock Account" : "Block Account",
                message: actionContext.isBlocking ? "Confirm to unblock \(actionContext.name)" : "Confirm to block \(actionContext.name)",
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
                        user: user,
                        authenticationBox: authenticationBox
                    )
                }   // end Task
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true, completion: nil)
        case .reportUser:
            Task {
                guard let user = menuContext.author else { return }
                
                let reportViewModel = ReportViewModel(
                    context: dependency.context,
                    user: user,
                    status: menuContext.status
                )
                
                dependency.coordinator.present(
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
            dependency.coordinator.present(
                scene: .activityViewController(
                    activityViewController: activityViewController,
                    sourceView: menuContext.button,
                    barButtonItem: menuContext.barButtonItem
                ),
                from: dependency,
                transition: .activityViewControllerPresent(animated: true, completion: nil)
            )
        case .deleteStatus:
            let alertController = UIAlertController(
                title: "Delete Post",
                message: "Are you sure you want to delete this post?",
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
                        status: status,
                        authenticationBox: authenticationBox
                    )
                }   // end Task
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true, completion: nil)
            
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
            
            let allToggled = status.isContentSensitiveToggled && status.isMediaSensitiveToggled
            
            status.update(isContentSensitiveToggled: !allToggled)
            status.update(isMediaSensitiveToggled: !allToggled)
        }
    }
    
//    static func responseToToggleMediaSensitiveAction(
//        dependency: NeedsDependency,
//        status: ManagedObjectRecord<Status>
//    ) async throws {
//        try await dependency.context.managedObjectContext.perform {
//            guard let _status = status.object(in: dependency.context.managedObjectContext) else { return }
//            let status = _status.reblog ?? _status
//            
//            status.update(isMediaSensitiveToggled: !status.isMediaSensitiveToggled)
//        }
//    }
    
}
