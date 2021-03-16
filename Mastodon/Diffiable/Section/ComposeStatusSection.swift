//
//  ComposeStatusSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterTextEditor

enum ComposeStatusSection: Equatable, Hashable {
    case repliedTo
    case status
}

extension ComposeStatusSection {
    enum ComposeKind {
        case post
        case reply(repliedToStatusObjectID: NSManagedObjectID)
    }
}

extension ComposeStatusSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        managedObjectContext: NSManagedObjectContext,
        composeKind: ComposeKind,
        textEditorViewTextAttributesDelegate: TextEditorViewTextAttributesDelegate
    ) -> UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem> {
        UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>(tableView: tableView) { [weak textEditorViewTextAttributesDelegate] tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .replyTo(let repliedToStatusObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeRepliedToTootContentTableViewCell.self), for: indexPath) as! ComposeRepliedToTootContentTableViewCell
                // TODO:
                return cell
            case .input(let replyToTootObjectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeTootContentTableViewCell.self), for: indexPath) as! ComposeTootContentTableViewCell
                managedObjectContext.perform {
                    guard let replyToTootObjectID = replyToTootObjectID,
                          let replyTo = managedObjectContext.object(with: replyToTootObjectID) as? Toot else {
                        cell.statusView.headerContainerStackView.isHidden = true
                        return
                    }
                    cell.statusView.headerContainerStackView.isHidden = false
                    cell.statusView.headerInfoLabel.text = "[TODO] \(replyTo.author.displayName)"
                }
                ComposeStatusSection.configure(cell: cell, attribute: attribute)
                cell.textEditorView.textAttributesDelegate = textEditorViewTextAttributesDelegate
                // self size input cell
                cell.composeContent
                    .receive(on: DispatchQueue.main)
                    .sink { text in
                        tableView.beginUpdates()
                        tableView.endUpdates()
                    }
                    .store(in: &cell.disposeBag)
                return cell
            }
        }
    }
}

extension ComposeStatusSection {
    static func configure(
        cell: ComposeTootContentTableViewCell,
        attribute: ComposeStatusItem.ComposeStatusAttribute
    ) {
        // set avatar
        attribute.avatarURL
            .receive(on: DispatchQueue.main)
            .sink { avatarURL in
                cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: avatarURL))
            }
            .store(in: &cell.disposeBag)
        // set display name and username
        Publishers.CombineLatest(
            attribute.displayName.eraseToAnyPublisher(),
            attribute.username.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { displayName, username in
            cell.statusView.nameLabel.text = displayName
            cell.statusView.usernameLabel.text = username
        }
        .store(in: &cell.disposeBag)
        
        // bind compose content
        cell.composeContent
            .map { $0 as String? }
            .assign(to: \.value, on: attribute.composeContent)
            .store(in: &cell.disposeBag)
    }
}
