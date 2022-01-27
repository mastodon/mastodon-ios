//
//  DataSourceProvider+NotificationTableViewCellDelegate.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-26.
//

import UIKit
import MetaTextKit
import MastodonUI
import CoreDataStack

// MARK: - Notification AuthorMenuAction
extension NotificationTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        menuButton button: UIButton,
        didSelectAction action: MastodonMenu.Action
    ) {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
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
                ),
                authenticationBox: authenticationBox
            )
        }   // end Task
    }
}

// MARK: - Notification Author Avatar
extension NotificationTableViewCellDelegate where Self: DataSourceProvider {
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

// MARK: - Status Content
extension NotificationTableViewCellDelegate where Self: DataSourceProvider {
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

// MARK: - Status Toolbar
extension NotificationTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        notificationView: NotificationView,
        statusView: StatusView, actionToolbarContainer: ActionToolbarContainer,
        buttonDidPressed button: UIButton,
        action: ActionToolbarContainer.Action
    ) {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
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
                authenticationBox: authenticationBox,
                sender: button
            )
        }   // end Task
    }
}


// MARK: - Status Author Avatar
extension NotificationTableViewCellDelegate where Self: DataSourceProvider {
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
extension NotificationTableViewCellDelegate where Self: DataSourceProvider {
    
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
        try await DataSourceFacade.responseToMetaTextAction(
            provider: self,
            target: .status,
            status: status,
            meta: meta
        )
    }
    
}
