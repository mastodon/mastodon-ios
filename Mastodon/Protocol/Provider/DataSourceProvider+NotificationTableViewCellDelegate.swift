//
//  DataSourceProvider+NotificationTableViewCellDelegate.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-26.
//

import UIKit
import MetaTextKit
import CoreDataStack
import MastodonCore
import MastodonUI

// MARK: - Notification AuthorMenuAction
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        menuButton button: UIButton,
        didSelectAction action: MastodonMenu.Action
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            let _author: ManagedObjectRecord<MastodonUser>? = try await self.context.managedObjectContext.perform {
                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
                return .init(objectID: notification.account.objectID)
            }
            guard let author = _author else {
                assertionFailure()
                return
            }
            
            try await DataSourceFacade.responseToMenuAction(
                dependency: self,
                action: action,
                menuContext: .init(
                    author: author,
                    status: nil,
                    button: button,
                    barButtonItem: nil
                )
            )
        }   // end Task
    }
}

// MARK: - Notification Author Avatar
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        authorAvatarButtonDidPressed button: AvatarButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            let _author: ManagedObjectRecord<MastodonUser>? = try await self.context.managedObjectContext.perform {
                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
                return .init(objectID: notification.account.objectID)
            }
            guard let author = _author else {
                assertionFailure()
                return
            }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                user: author
            )
        }   // end Task
    }
}

// MARK: - Follow Request
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
 
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        acceptFollowRequestButtonDidPressed button: UIButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            try await DataSourceFacade.responseToUserFollowRequestAction(
                dependency: self,
                notification: notification,
                query: .accept
            )
        } // end Task
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        rejectFollowRequestButtonDidPressed button: UIButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            try await DataSourceFacade.responseToUserFollowRequestAction(
                dependency: self,
                notification: notification,
                query: .reject
            )
        } // end Task
    }
    
}

// MARK: - Status Content
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        statusView: StatusView,
        metaText: MetaText,
        didSelectMeta meta: Meta
    ) {
        Task {
            try await responseToStatusMeta(cell, didSelectMeta: meta)
        }   // end Task
    }
}

private struct NotificationMediaTransitionContext {
    let status: ManagedObjectRecord<Status>
    let needsToggleMediaSensitive: Bool
}

extension NotificationTableViewCellDelegate where Self: DataSourceProvider & MediaPreviewableViewController {
    
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        statusView: StatusView,
        mediaGridContainerView: MediaGridContainerView,
        mediaView: MediaView,
        didSelectMediaViewAt index: Int
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(record) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            let managedObjectContext = self.context.managedObjectContext
            let _mediaTransitionContext: NotificationMediaTransitionContext? = try await managedObjectContext.perform {
                guard let notification = record.object(in: managedObjectContext) else { return nil }
                guard let _status = notification.status else { return nil }
                let status = _status.reblog ?? _status
                return NotificationMediaTransitionContext(
                    status: .init(objectID: status.objectID),
                    needsToggleMediaSensitive: status.isSensitiveToggled ? !status.sensitive : status.sensitive
                )
            }

            guard let mediaTransitionContext = _mediaTransitionContext else { return }
            
            guard !mediaTransitionContext.needsToggleMediaSensitive else {
                try await DataSourceFacade.responseToToggleSensitiveAction(
                    dependency: self,
                    status: mediaTransitionContext.status
                )
                return
            }
            
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: self,
                status: mediaTransitionContext.status,
                previewContext: DataSourceFacade.AttachmentPreviewContext(
                    containerView: .mediaGridContainerView(mediaGridContainerView),
                    mediaView: mediaView,
                    index: index
                )
            )
        }   // end Task
    }

    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        quoteStatusView: StatusView,
        mediaGridContainerView: MediaGridContainerView,
        mediaView: MediaView,
        didSelectMediaViewAt index: Int
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(record) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            let managedObjectContext = self.context.managedObjectContext
            let _mediaTransitionContext: NotificationMediaTransitionContext? = try await managedObjectContext.perform {
                guard let notification = record.object(in: managedObjectContext) else { return nil }
                guard let _status = notification.status else { return nil }
                let status = _status.reblog ?? _status
                return NotificationMediaTransitionContext(
                    status: .init(objectID: status.objectID),
                    needsToggleMediaSensitive: status.isMediaSensitive ? !status.isSensitiveToggled : false
                )
            }

            guard let mediaTransitionContext = _mediaTransitionContext else { return }
            
            guard !mediaTransitionContext.needsToggleMediaSensitive else {
                try await DataSourceFacade.responseToToggleSensitiveAction(
                    dependency: self,
                    status: mediaTransitionContext.status
                )
                return
            }
            
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: self,
                status: mediaTransitionContext.status,
                previewContext: DataSourceFacade.AttachmentPreviewContext(
                    containerView: .mediaGridContainerView(mediaGridContainerView),
                    mediaView: mediaView,
                    index: index
                )
            )
        }   // end Task
    }

}

// MARK: - Status Toolbar
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider  {
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        statusView: StatusView, actionToolbarContainer: ActionToolbarContainer,
        buttonDidPressed button: UIButton,
        action: ActionToolbarContainer.Action
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            let _status: ManagedObjectRecord<Status>? = try await self.context.managedObjectContext.perform {
                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
                guard let status = notification.status else { return nil }
                return .init(objectID: status.objectID)
            }
            guard let status = _status else {
                assertionFailure()
                return
            }
            try await DataSourceFacade.responseToActionToolbar(
                provider: self,
                status: status,
                action: action,
                sender: button
            )
        }   // end Task
    }
}

// MARK: - Status Author Avatar
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        quoteStatusView: StatusView,
        authorAvatarButtonDidPressed button: AvatarButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            let _author: ManagedObjectRecord<MastodonUser>? = try await self.context.managedObjectContext.perform {
                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
                guard let status = notification.status else { return nil }
                return .init(objectID: status.author.objectID)
            }
            guard let author = _author else {
                assertionFailure()
                return
            }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                user: author
            )
        }   // end Task
    }
}

// MARK: - Status Content
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        quoteStatusView: StatusView, metaText: MetaText,
        didSelectMeta meta: Meta
    ) {
        Task {
            try await responseToStatusMeta(cell, didSelectMeta: meta)
        }   // end Task
    }
    
    private func responseToStatusMeta(
        _ cell: UITableViewCell,
        didSelectMeta meta: Meta
    ) async throws {
        let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
        guard let item = await item(from: source) else {
            assertionFailure()
            return
        }
        guard case let .notification(notification) = item else {
            assertionFailure("only works for notification item")
            return
        }
        let _status: ManagedObjectRecord<Status>? = try await self.context.managedObjectContext.perform {
            guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
            guard let status = notification.status else { return nil }
            return .init(objectID: status.objectID)
        }
        guard let status = _status else {
            assertionFailure()
            return
        }
        try await DataSourceFacade.responseToMetaTextAction(
            provider: self,
            target: .status,
            status: status,
            meta: meta
        )
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        statusView: StatusView,
        spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for notification item")
                return
            }
            let _status: ManagedObjectRecord<Status>? = try await self.context.managedObjectContext.perform {
                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
                guard let status = notification.status else { return nil }
                return .init(objectID: status.objectID)
            }
            guard let status = _status else {
                assertionFailure()
                return
            }
            try await DataSourceFacade.responseToToggleSensitiveAction(
                dependency: self,
                status: status
            )
        }   // end Task
    }

    
//    func tableViewCell(
//        _ cell: UITableViewCell, notificationView: NotificationView,
//        statusView: StatusView,
//        spoilerBannerViewDidPressed bannerView: SpoilerBannerView
//    ) {
//        Task {
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                assertionFailure()
//                return
//            }
//            guard case let .notification(notification) = item else {
//                assertionFailure("only works for notification item")
//                return
//            }
//            let _status: ManagedObjectRecord<Status>? = try await self.context.managedObjectContext.perform {
//                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
//                guard let status = notification.status else { return nil }
//                return .init(objectID: status.objectID)
//            }
//            guard let status = _status else {
//                assertionFailure()
//                return
//            }
//            try await DataSourceFacade.responseToToggleSensitiveAction(
//                dependency: self,
//                status: status
//            )
//        }   // end Task
//    }

    
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        quoteStatusView: StatusView,
        spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for notification item")
                return
            }
            let _status: ManagedObjectRecord<Status>? = try await self.context.managedObjectContext.perform {
                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
                guard let status = notification.status else { return nil }
                return .init(objectID: status.objectID)
            }
            guard let status = _status else {
                assertionFailure()
                return
            }
            try await DataSourceFacade.responseToToggleSensitiveAction(
                dependency: self,
                status: status
            )
        }   // end Task
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        quoteStatusView: StatusView,
        spoilerBannerViewDidPressed bannerView: SpoilerBannerView
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for notification item")
                return
            }
            let _status: ManagedObjectRecord<Status>? = try await self.context.managedObjectContext.perform {
                guard let notification = notification.object(in: self.context.managedObjectContext) else { return nil }
                guard let status = notification.status else { return nil }
                return .init(objectID: status.objectID)
            }
            guard let status = _status else {
                assertionFailure()
                return
            }
            try await DataSourceFacade.responseToToggleSensitiveAction(
                dependency: self,
                status: status
            )
        }   // end Task
    }

    
}

// MARK: a11y
extension NotificationTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(_ cell: UITableViewCell, notificationView: NotificationView, accessibilityActivate: Void) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                return
            }
            switch item {
            case .status(let status):
                await DataSourceFacade.coordinateToStatusThreadScene(
                    provider: self,
                    target: .status,    // remove reblog wrapper
                    status: status
                )
            case .user(let user):
                await DataSourceFacade.coordinateToProfileScene(
                    provider: self,
                    user: user
                )
            case .notification:
                assertionFailure("TODO")
            default:
                assertionFailure("TODO")
            }
        }   // end Task
    }
}
