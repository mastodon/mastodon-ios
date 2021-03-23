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
    case poll
}

extension ComposeStatusSection {
    enum ComposeKind {
        case post
        case reply(repliedToStatusObjectID: NSManagedObjectID)
    }
}

extension ComposeStatusSection {
    
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency,
        managedObjectContext: NSManagedObjectContext,
        composeKind: ComposeKind,
        textEditorViewTextAttributesDelegate: TextEditorViewTextAttributesDelegate,
        composeStatusAttachmentTableViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate,
        composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate,
        composeStatusNewPollOptionCollectionViewCellDelegate: ComposeStatusNewPollOptionCollectionViewCellDelegate
    ) -> UICollectionViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .replyTo(let repliedToStatusObjectID):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeRepliedToTootContentCollectionViewCell.self), for: indexPath) as! ComposeRepliedToTootContentCollectionViewCell
                return cell
            case .input(let replyToTootObjectID, let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusContentCollectionViewCell.self), for: indexPath) as! ComposeStatusContentCollectionViewCell
                cell.textEditorView.text = attribute.composeContent.value ?? ""
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
                cell.composeContent
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { text in
                        // self size input cell
                        collectionView.collectionViewLayout.invalidateLayout()
                        // bind input data
                        attribute.composeContent.value = text
                    }
                    .store(in: &cell.disposeBag)
                return cell
            case .attachment(let attachmentService):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusAttachmentCollectionViewCell.self), for: indexPath) as! ComposeStatusAttachmentCollectionViewCell
                cell.attachmentContainerView.descriptionTextView.text = attachmentService.description.value
                cell.delegate = composeStatusAttachmentTableViewCellDelegate
                attachmentService.imageData
                    .receive(on: DispatchQueue.main)
                    .sink { imageData in
                        let size = cell.attachmentContainerView.previewImageView.frame.size != .zero ? cell.attachmentContainerView.previewImageView.frame.size : CGSize(width: 1, height: 1)
                        guard let imageData = imageData,
                              let image = UIImage(data: imageData) else {
                            let placeholder = UIImage.placeholder(
                                size: size,
                                color: Asset.Colors.Background.systemGroupedBackground.color
                            )
                            .af.imageRounded(
                                withCornerRadius: AttachmentContainerView.containerViewCornerRadius
                            )
                            cell.attachmentContainerView.previewImageView.image = placeholder
                            return
                        }
                        cell.attachmentContainerView.previewImageView.image = image
                            .af.imageAspectScaled(toFill: size)
                            .af.imageRounded(withCornerRadius: AttachmentContainerView.containerViewCornerRadius)
                    }
                    .store(in: &cell.disposeBag)
                Publishers.CombineLatest(
                    attachmentService.uploadStateMachineSubject.eraseToAnyPublisher(),
                    attachmentService.error.eraseToAnyPublisher()
                )
                .receive(on: DispatchQueue.main)
                .sink { uploadState, error  in
                    cell.attachmentContainerView.emptyStateView.isHidden = error == nil
                    cell.attachmentContainerView.descriptionBackgroundView.isHidden = error != nil
                    if let _ = error {
                        cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                    } else {
                        guard let uploadState = uploadState else { return }
                        switch uploadState {
                        case is MastodonAttachmentService.UploadState.Finish,
                             is MastodonAttachmentService.UploadState.Fail:
                            cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                        default:
                            break
                        }
                    }
                }
                .store(in: &cell.disposeBag)
                NotificationCenter.default.publisher(
                    for: UITextView.textDidChangeNotification,
                    object: cell.attachmentContainerView.descriptionTextView
                )
                .receive(on: DispatchQueue.main)
                .sink { notification in
                    guard let textField = notification.object as? UITextView else { return }
                    let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                    attachmentService.description.value = text
                }
                .store(in: &cell.disposeBag)
                return cell
            case .poll(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionCollectionViewCell
                cell.pollOptionView.optionTextField.text = attribute.option.value
                cell.pollOption
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.value, on: attribute.option)
                    .store(in: &cell.disposeBag)
                cell.delegate = composeStatusPollOptionCollectionViewCellDelegate
                return cell
            case .newPoll:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusNewPollOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusNewPollOptionCollectionViewCell
                cell.delegate = composeStatusNewPollOptionCollectionViewCellDelegate
                return cell
            }
        }
    }
}

extension ComposeStatusSection {
    static func configure(
        cell: ComposeStatusContentCollectionViewCell,
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
