//
//  DataSourceProvider+StatusTableViewCellDelegate.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import UIKit
import MetaTextKit
import MastodonUI
import CoreDataStack

// MARK: - header
extension StatusTableViewCellDelegate where Self: DataSourceProvider {
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        headerDidPressed header: UIView
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                target: .reblog,      // keep the wrapper for header author
                status: status
            )
        }
    }

}

// MARK: - avatar button
extension StatusTableViewCellDelegate where Self: DataSourceProvider {

    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        authorAvatarButtonDidPressed button: AvatarButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                target: .status,
                status: status
            )
        }
    }

}

// MARK: - content
extension StatusTableViewCellDelegate where Self: DataSourceProvider {
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        metaText: MetaText,
        didSelectMeta meta: Meta
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
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
    
}

// MARK: - media
extension StatusTableViewCellDelegate where Self: DataSourceProvider & MediaPreviewableViewController {
    
    func tableViewCell(
        _ cell: UITableViewCell,
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
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            let managedObjectContext = self.context.managedObjectContext
            let needsToggleMediaSensitive: Bool = try await managedObjectContext.perform {
                guard let _status = status.object(in: managedObjectContext) else { return false }
                let status = _status.reblog ?? _status
                guard status.sensitive else { return false }
                guard status.isMediaSensitiveToggled else { return true }
                return false
            }
            
            guard !needsToggleMediaSensitive else {
                try await DataSourceFacade.responseToToggleMediaSensitiveAction(
                    dependency: self,
                    status: status
                )
                return
            }
            
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: self,
                status: status,
                previewContext: DataSourceFacade.AttachmentPreviewContext(
                    containerView: .mediaGridContainerView(mediaGridContainerView),
                    mediaView: mediaView,
                    index: index
                )
            )
        }   // end Task
    }

}


// MARK: - poll
extension StatusTableViewCellDelegate where Self: DataSourceProvider {
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        pollTableView tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        guard let pollTableViewDiffableDataSource = statusView.pollTableViewDiffableDataSource else { return }
        guard let pollItem = pollTableViewDiffableDataSource.itemIdentifier(for: indexPath) else { return }
                
        let managedObjectContext = context.managedObjectContext
        
        Task {
            guard case let .option(pollOption) = pollItem else {
                assertionFailure("only works for status data provider")
                return
            }
                     
            var _poll: ManagedObjectRecord<Poll>?
            var _isMultiple: Bool?
            var _choice: Int?
            
            try await managedObjectContext.performChanges {
                guard let pollOption = pollOption.object(in: managedObjectContext) else { return }
                let poll = pollOption.poll
                _poll = .init(objectID: poll.objectID)

                _isMultiple = poll.multiple
                guard !poll.isVoting else { return }
                
                if !poll.multiple {
                    for option in poll.options where option != pollOption {
                        option.update(isSelected: false)
                    }
                    
                    // mark voting
                    poll.update(isVoting: true)
                    // set choice
                    _choice = Int(pollOption.index)
                }
                
                pollOption.update(isSelected: !pollOption.isSelected)
                poll.update(updatedAt: Date())
            }
            
            // Trigger vote API request for
            guard let poll = _poll,
                  _isMultiple == false,
                  let choice = _choice
            else { return }
            
            do {
                _ = try await context.apiService.vote(
                    poll: poll,
                    choices: [choice],
                    authenticationBox: authenticationBox
                )
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): vote poll for \(choice) success")
            } catch {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): vote poll fail: \(error.localizedDescription)")
                
                // restore voting state
                try await managedObjectContext.performChanges {
                    guard let pollOption = pollOption.object(in: managedObjectContext) else { return }
                    let poll = pollOption.poll
                    poll.update(isVoting: false)
                }
            }
            
        }   // end Task
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        pollVoteButtonPressed button: UIButton
    ) {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        guard let pollTableViewDiffableDataSource = statusView.pollTableViewDiffableDataSource else { return }
        guard let firstPollItem = pollTableViewDiffableDataSource.snapshot().itemIdentifiers.first else { return }
        guard case let .option(firstPollOption) = firstPollItem else { return }
        
        let managedObjectContext = context.managedObjectContext
        
        Task {
            var _poll: ManagedObjectRecord<Poll>?
            var _choices: [Int]?
            
            try await managedObjectContext.performChanges {
                guard let poll = firstPollOption.object(in: managedObjectContext)?.poll else { return }
                _poll = .init(objectID: poll.objectID)
                
                guard poll.multiple else { return }
                
                // mark voting
                poll.update(isVoting: true)
                // set choice
                _choices = poll.options
                    .filter { $0.isSelected }
                    .map { Int($0.index) }
                
                poll.update(updatedAt: Date())
            }
            
            // Trigger vote API request for
            guard let poll = _poll,
                  let choices = _choices
            else { return }
            
            do {
                _ = try await context.apiService.vote(
                    poll: poll,
                    choices: choices,
                    authenticationBox: authenticationBox
                )
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): vote poll for \(choices) success")
            } catch {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): vote poll fail: \(error.localizedDescription)")
                
                // restore voting state
                try await managedObjectContext.performChanges {
                    guard let poll = poll.object(in: managedObjectContext) else { return }
                    poll.update(isVoting: false)
                }
            }
            
        }   // end Task
    }

}

// MARK: - toolbar
extension StatusTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        actionToolbarContainer: ActionToolbarContainer,
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
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
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

// MARK: - menu button
extension StatusTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
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
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            let _author: ManagedObjectRecord<MastodonUser>? = try await self.context.managedObjectContext.perform {
                guard let _status = status.object(in: self.context.managedObjectContext) else { return nil }
                let author = (_status.reblog ?? _status).author
                return .init(objectID: author.objectID)
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
                    status: status,
                    button: button,
                    barButtonItem: nil
                ),
                authenticationBox: authenticationBox
            )
        }   // end Task
    }

}

// MARK: - content warning
extension StatusTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        contentWarningToggleButtonDidPressed button: UIButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            try await DataSourceFacade.responseToToggleSensitiveAction(
                dependency: self,
                status: status
            )
        }   // end Task
    }
}

