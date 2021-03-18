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
import AlamofireImage

enum ComposeStatusSection: Equatable, Hashable {
    case repliedTo
    case status
    case attachment
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
        textEditorViewTextAttributesDelegate: TextEditorViewTextAttributesDelegate,
        composeStatusAttachmentTableViewCellDelegate: ComposeStatusAttachmentTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem> {
        UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>(tableView: tableView) { [weak textEditorViewTextAttributesDelegate, weak composeStatusAttachmentTableViewCellDelegate] tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .replyTo(let repliedToStatusObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeRepliedToTootContentTableViewCell.self), for: indexPath) as! ComposeRepliedToTootContentTableViewCell
                // TODO:
                return cell
            case .input(let replyToTootObjectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeStatusContentTableViewCell.self), for: indexPath) as! ComposeStatusContentTableViewCell
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
            case .attachment(let attachmentService):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeStatusAttachmentTableViewCell.self), for: indexPath) as! ComposeStatusAttachmentTableViewCell
                cell.delegate = composeStatusAttachmentTableViewCellDelegate
                attachmentService.imageData
                    .receive(on: DispatchQueue.main)
                    .sink { imageData in
                        guard let imageData = imageData,
                              let image = UIImage(data: imageData) else {
                            let placeholder = UIImage.placeholder(
                                size: cell.attachmentContainerView.previewImageView.frame.size,
                                color: Asset.Colors.Background.systemGroupedBackground.color
                            )
                            .af.imageRounded(
                                withCornerRadius: AttachmentContainerView.containerViewCornerRadius
                            )
                            cell.attachmentContainerView.previewImageView.image = placeholder
                            return
                        }
                        cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                        cell.attachmentContainerView.previewImageView.image = image
                            .af.imageAspectScaled(toFill: cell.attachmentContainerView.previewImageView.frame.size)
                            .af.imageRounded(withCornerRadius: AttachmentContainerView.containerViewCornerRadius)
                    }
                    .store(in: &cell.disposeBag)
                attachmentService.error
                    .receive(on: DispatchQueue.main)
                    .sink { error in
                        cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                        cell.attachmentContainerView.emptyStateView.isHidden = error == nil
                    }
                    .store(in: &cell.disposeBag)
                return cell
            }
        }
    }
}

extension ComposeStatusSection {
    static func configure(
        cell: ComposeStatusContentTableViewCell,
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
