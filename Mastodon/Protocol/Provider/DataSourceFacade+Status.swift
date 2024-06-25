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
import MastodonSDK

// Delete
extension DataSourceFacade {
    
    static func responseToDeleteStatus(
        dependency: NeedsDependency & AuthContextProvider & DataSourceProvider,
        status: MastodonStatus
    ) async throws {
        let deletedStatus = try await dependency.context.apiService.deleteStatus(
            status: status,
            authenticationBox: dependency.authContext.mastodonAuthenticationBox
        ).value.asMastodonStatus
        
        dependency.update(status: deletedStatus, intent: .delete)
    }
    
}

// Share
extension DataSourceFacade {
    
    @MainActor
    public static func responseToStatusShareAction(
        provider: DataSourceProvider,
        status: MastodonStatus,
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
        status: MastodonStatus
    ) async throws -> UIActivityViewController {
        var activityItems: [Any] = {
            guard let url = URL(string: status.entity.url ?? status.entity.uri) else { return [] }
            return [
                URLActivityItem(url: url)
            ]
        }()

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
        status: MastodonStatus,
        action: ActionToolbarContainer.Action,
        sender: UIButton
    ) async throws {
        let _status = status.reblog ?? status

        switch action {
        case .reply:
            FeedbackGenerator.shared.generate(.selectionChanged)

            let composeViewModel = ComposeViewModel(
                context: provider.context,
                authContext: provider.authContext,
                composeContext: .composeStatus,
                destination: .reply(parent: _status)
            )
            _ = provider.coordinator.present(
                scene: .compose(viewModel: composeViewModel),
                from: provider,
                transition: .modal(animated: true, completion: nil)
            )
        case .reblog:
            try await DataSourceFacade.responseToStatusReblogAction(
                provider: provider,
                status: _status
            )
        case .like:
            try await DataSourceFacade.responseToStatusFavoriteAction(
                provider: provider,
                status: _status
            )
        case .share:
            try await DataSourceFacade.responseToStatusShareAction(
                provider: provider,
                status: _status,
                button: sender
            )
        }   // end switch
    }   // end func

}

// menu
extension DataSourceFacade {
    
    struct MenuContext {
        let author: Mastodon.Entity.Account
        let statusViewModel: StatusView.ViewModel?
        let button: UIButton?
        let barButtonItem: UIBarButtonItem?
    }
    
    @MainActor
    static func responseToMenuAction<T>(
        dependency: UIViewController & NeedsDependency & AuthContextProvider & DataSourceProvider,
        action: MastodonMenu.Action,
        menuContext: MenuContext,
        completion: ((T) -> Void)? = { (param: Void) in }
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
                        try await DataSourceFacade.responseToShowHideReblogAction(
                            dependency: dependency,
                            account: menuContext.author
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
                guard let dependency else { return }
                Task {
                    let newRelationship = try await DataSourceFacade.responseToUserMuteAction(
                        dependency: dependency,
                        account: menuContext.author
                    )

                    if let completion, let relationship = newRelationship as? T {
                        completion(relationship)
                    }
                }
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
                guard let dependency else { return }
                Task {
                    let newRelationship = try await DataSourceFacade.responseToUserBlockAction(
                        dependency: dependency,
                        account: menuContext.author
                    )

                    if let completion, let relationship = newRelationship as? T {
                        completion(relationship)
                    }
                }
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true)
        case .reportUser:
            guard let relationship = try? await dependency.context.apiService.relationship(forAccounts: [menuContext.author], authenticationBox: dependency.authContext.mastodonAuthenticationBox).value.first else { return }

            let reportViewModel = ReportViewModel(
                context: dependency.context,
                authContext: dependency.authContext,
                account: menuContext.author,
                relationship: relationship,
                status: menuContext.statusViewModel?.originalStatus
            )

            _ = dependency.coordinator.present(
                scene: .report(viewModel: reportViewModel),
                from: dependency,
                transition: .modal(animated: true, completion: nil)
            )
        case .shareUser:
            let activityViewController = DataSourceFacade.createActivityViewController(
                dependency: dependency,
                account: menuContext.author
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
        case .bookmarkStatus:
                guard let status = menuContext.statusViewModel?.originalStatus else {
                    assertionFailure()
                    return
                }
                try await DataSourceFacade.responseToStatusBookmarkAction(
                    provider: dependency,
                    status: status
                )
        case .shareStatus:
            guard let status: MastodonStatus = menuContext.statusViewModel?.originalStatus?.reblog ?? menuContext.statusViewModel?.originalStatus else {
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
        case .deleteStatus:
            if UserDefaults.shared.askBeforeDeletingAPost {
                let alertController = UIAlertController(
                    title: L10n.Common.Alerts.DeletePost.title,
                    message: L10n.Common.Alerts.DeletePost.message,
                    preferredStyle: .alert
                )
                let confirmAction = UIAlertAction(
                    title: L10n.Common.Controls.Actions.delete,
                    style: .destructive
                ) { [weak dependency] _ in
                    guard let dependency else { return }
                    guard let status = menuContext.statusViewModel?.originalStatus else { return }
                    performDeletion(of: status, with: dependency)
                }
                alertController.addAction(confirmAction)
                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
                alertController.addAction(cancelAction)
                dependency.present(alertController, animated: true)
            } else {
                guard let status = menuContext.statusViewModel?.originalStatus else { return }
                performDeletion(of: status, with: dependency)
            }
        case .translateStatus:
            guard let status = menuContext.statusViewModel?.originalStatus?.reblog ?? menuContext.statusViewModel?.originalStatus else { return }

            do {
                let translation = try await DataSourceFacade.translateStatus(provider: dependency,status: status)

                menuContext.statusViewModel?.translation = translation
            } catch TranslationFailure.emptyOrInvalidResponse {
                menuContext.statusViewModel?.isCurrentlyTranslating = false
                let alertController = UIAlertController(title: L10n.Common.Alerts.TranslationFailed.title, message: L10n.Common.Alerts.TranslationFailed.message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: L10n.Common.Alerts.TranslationFailed.button, style: .default))
                dependency.present(alertController, animated: true)
            }
        case .editStatus:

            guard let status = menuContext.statusViewModel?.originalStatus else { return }

            let statusSource = try await dependency.context.apiService.getStatusSource(
                forStatusID: status.id,
                authenticationBox: dependency.authContext.mastodonAuthenticationBox
            ).value

            let editStatusViewModel = ComposeViewModel(
                context: dependency.coordinator.appContext,
                authContext: dependency.authContext,
                composeContext: .editStatus(status: status, statusSource: statusSource),
                destination: .topLevel)
            _ = dependency.coordinator.present(scene: .editStatus(viewModel: editStatusViewModel), transition: .modal(animated: true))

        case .showOriginal:
            // do nothing, as the translation is reverted in `StatusTableViewCellDelegate` in `DataSourceProvider+StatusTableViewCellDelegate.swift`.
            break
        case .followUser(_):
            _ = try await DataSourceFacade.responseToUserFollowAction(dependency: dependency,
                                                                  account: menuContext.author)
        case .blockDomain(let context):
            let title: String
            let message: String
            let actionTitle: String

            if context.isBlocking {
                title = L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.title
                message = L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.message(context.domain)
                actionTitle = L10n.Common.Controls.Actions.unblockDomain(context.domain)
            } else {
                title = L10n.Scene.Profile.RelationshipActionAlert.ConfirmBlockDomain.title
                message = L10n.Common.Alerts.BlockDomain.title(context.domain)
                actionTitle = L10n.Common.Alerts.BlockDomain.blockEntireDomain
            }

            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )

            let confirmAction = UIAlertAction(title: actionTitle, style: .destructive ) { [weak dependency] _ in
                guard let dependency else { return }
                Task {
                    try await DataSourceFacade.responseToDomainBlockAction(
                        dependency: dependency,
                        account: menuContext.author
                    )
                }
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
            alertController.addAction(cancelAction)
            dependency.present(alertController, animated: true)
        case .boostStatus(_):
            guard let status: MastodonStatus = menuContext.statusViewModel?.originalStatus?.reblog ?? menuContext.statusViewModel?.originalStatus else {
                assertionFailure()
                return
            }

            try await responseToStatusReblogAction(provider: dependency, status: status)
        case .favoriteStatus(_):
            guard let status: MastodonStatus = menuContext.statusViewModel?.originalStatus?.reblog ?? menuContext.statusViewModel?.originalStatus else {
                assertionFailure()
                return
            }

            try await responseToStatusFavoriteAction(provider: dependency, status: status)
        case .copyStatusLink:
            guard let status: MastodonStatus = menuContext.statusViewModel?.originalStatus?.reblog ?? menuContext.statusViewModel?.originalStatus else {
                assertionFailure()
                return
            }

            UIPasteboard.general.string = status.entity.url
        case .openStatusInBrowser:
            guard
                let status: MastodonStatus = menuContext.statusViewModel?.originalStatus?.reblog ?? menuContext.statusViewModel?.originalStatus,
                let urlString = status.entity.url,
                let url = URL(string: urlString)
            else {
                assertionFailure()
                return
            }

            dependency.coordinator.present(scene: .safari(url: url), transition: .safariPresent(animated: true))
        case .copyProfileLink(let url):
            UIPasteboard.general.string = url?.absoluteString
        case .openUserInBrowser(let url):
            guard let url else { return }

            dependency.coordinator.present(scene: .safari(url: url), transition: .safariPresent(animated: true))
        }
    }
}

extension DataSourceFacade {
    @MainActor
    static func responseToToggleSensitiveAction(
        dependency: NeedsDependency & DataSourceProvider,
        status: MastodonStatus
    ) async throws {
        let _status = status.reblog ?? status
        
        let newStatus: MastodonStatus = .fromEntity(_status.entity)
        newStatus.isSensitiveToggled = !_status.isSensitiveToggled
        
        dependency.update(status: newStatus, intent: .toggleSensitive(newStatus.isSensitiveToggled))
    }
    
}

private extension DataSourceFacade {
    static func performDeletion(of status: MastodonStatus, with dependency: NeedsDependency & AuthContextProvider & DataSourceProvider) {
        Task {
            try await DataSourceFacade.responseToDeleteStatus(
                dependency: dependency,
                status: status
            )
        }
    }
}
