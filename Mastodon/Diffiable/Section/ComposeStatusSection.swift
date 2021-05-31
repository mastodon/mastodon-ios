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
        case hashtag(hashtag: String)
        case mention(mastodonUserObjectID: NSManagedObjectID)
        case reply(repliedToStatusObjectID: NSManagedObjectID)
    }
}

extension ComposeStatusSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency,
        managedObjectContext: NSManagedObjectContext,
        composeKind: ComposeKind,
        repliedToCellFrameSubscriber: CurrentValueSubject<CGRect, Never>,
        customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel,
        textEditorViewTextAttributesDelegate: TextEditorViewTextAttributesDelegate,
        textEditorViewChangeObserver: TextEditorViewChangeObserver,
        composeStatusAttachmentTableViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate,
        composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate,
        composeStatusNewPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate,
        composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate
    ) -> UICollectionViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [
            weak customEmojiPickerInputViewModel,
            weak textEditorViewTextAttributesDelegate,
            weak textEditorViewChangeObserver,
            weak composeStatusAttachmentTableViewCellDelegate,
            weak composeStatusPollOptionCollectionViewCellDelegate,
            weak composeStatusNewPollOptionCollectionViewCellDelegate,
            weak composeStatusPollExpiresOptionCollectionViewCellDelegate
        ] collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .replyTo(let replyToStatusObjectID):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeRepliedToStatusContentCollectionViewCell.self), for: indexPath) as! ComposeRepliedToStatusContentCollectionViewCell
                // set empty text before retrieve real data to fix pseudo-text display issue
                cell.statusView.nameLabel.text = " "
                cell.statusView.usernameLabel.text = " "
                managedObjectContext.performAndWait {
                    guard let replyTo = managedObjectContext.object(with: replyToStatusObjectID) as? Status else {
                        return
                    }
                    let status = replyTo.reblog ?? replyTo
                    
                    // set avatar
                    cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
                    // set name username
                    cell.statusView.nameLabel.text = {
                        let author = status.author
                        return author.displayName.isEmpty ? author.username : author.displayName
                    }()
                    cell.statusView.usernameLabel.text = "@" + (status.reblog ?? status).author.acct
                    // set text
                    //status.emoji
                    cell.statusView.activeTextLabel.configure(content: status.content, emojiDict: [:])
                    // set date
                    cell.statusView.dateLabel.text = status.createdAt.shortTimeAgoSinceNow
                    
                    cell.framePublisher.assign(to: \.value, on: repliedToCellFrameSubscriber).store(in: &cell.disposeBag)
                }
                return cell
            case .input(let replyToStatusObjectID, let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusContentCollectionViewCell.self), for: indexPath) as! ComposeStatusContentCollectionViewCell
                cell.statusContentWarningEditorView.textView.text = attribute.contentWarningContent.value
                cell.textEditorView.text = attribute.composeContent.value ?? ""
                managedObjectContext.performAndWait {
                    guard let replyToStatusObjectID = replyToStatusObjectID,
                          let replyTo = managedObjectContext.object(with: replyToStatusObjectID) as? Status else {
                        cell.statusView.headerContainerView.isHidden = true
                        return
                    }
                    cell.statusView.headerContainerView.isHidden = false
                    cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.replyIconImage)
                    cell.statusView.headerInfoLabel.text = L10n.Scene.Compose.replyingToUser(replyTo.author.displayNameWithFallback)
                }
                ComposeStatusSection.configureStatusContent(cell: cell, attribute: attribute)
                cell.textEditorView.textAttributesDelegate = textEditorViewTextAttributesDelegate
                cell.textEditorViewChangeObserver = textEditorViewChangeObserver    // relay
                cell.composeContent
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak collectionView] text in
                        guard let collectionView = collectionView else { return }
                        // self size input cell
                        // needs restore content offset to resolve issue #83
                        let oldContentOffset = collectionView.contentOffset
                        collectionView.collectionViewLayout.invalidateLayout()
                        collectionView.layoutIfNeeded()
                        collectionView.contentOffset = oldContentOffset

                        // bind input data
                        attribute.composeContent.value = text
                    }
                    .store(in: &cell.disposeBag)
                attribute.isContentWarningComposing
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell, weak collectionView] isContentWarningComposing in
                        guard let cell = cell else { return }
                        guard let collectionView = collectionView else { return }
                        // self size input cell
                        collectionView.collectionViewLayout.invalidateLayout()
                        cell.statusContentWarningEditorView.containerView.isHidden = !isContentWarningComposing
                        cell.statusContentWarningEditorView.alpha = 0
                        UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseOut]) {
                            cell.statusContentWarningEditorView.alpha = 1
                        } completion: { _ in
                            // do nothing
                        }
                    }
                    .store(in: &cell.disposeBag)
                cell.contentWarningContent
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak collectionView] text in
                        guard let collectionView = collectionView else { return }
                        // self size input cell
                        collectionView.collectionViewLayout.invalidateLayout()
                        // bind input data
                        attribute.contentWarningContent.value = text
                    }
                    .store(in: &cell.disposeBag)
                ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplacableTextInput: cell.textEditorView, disposeBag: &cell.disposeBag)
                ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplacableTextInput: cell.statusContentWarningEditorView.textView, disposeBag: &cell.disposeBag)

                return cell
            case .attachment(let attachmentService):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusAttachmentCollectionViewCell.self), for: indexPath) as! ComposeStatusAttachmentCollectionViewCell
                cell.attachmentContainerView.descriptionTextView.text = attachmentService.description.value
                cell.delegate = composeStatusAttachmentTableViewCellDelegate
                attachmentService.thumbnailImage
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] thumbnailImage in
                        guard let cell = cell else { return }
                        let size = cell.attachmentContainerView.previewImageView.frame.size != .zero ? cell.attachmentContainerView.previewImageView.frame.size : CGSize(width: 1, height: 1)
                        guard let image = thumbnailImage else {
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
                .sink { [weak cell, weak attachmentService] uploadState, error  in
                    guard let cell = cell else { return }
                    guard let attachmentService = attachmentService else { return }
                    cell.attachmentContainerView.emptyStateView.isHidden = error == nil
                    cell.attachmentContainerView.descriptionBackgroundView.isHidden = error != nil
                    if let error = error {
                        cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                        cell.attachmentContainerView.emptyStateView.label.text = error.localizedDescription
                    } else {
                        guard let uploadState = uploadState else { return }
                        switch uploadState {
                        case is MastodonAttachmentService.UploadState.Finish,
                             is MastodonAttachmentService.UploadState.Fail:
                            cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                            cell.attachmentContainerView.emptyStateView.label.text = {
                                if let file = attachmentService.file.value {
                                    switch file {
                                    case .jpeg, .png, .gif:
                                        return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.photo)
                                    case .other:
                                        return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.video)
                                    }
                                } else {
                                    return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.photo)
                                }
                            }()
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
            case .pollOption(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionCollectionViewCell
                cell.pollOptionView.optionTextField.text = attribute.option.value
                cell.pollOptionView.optionTextField.placeholder = L10n.Scene.Compose.Poll.optionNumber(indexPath.item + 1)
                cell.pollOption
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.value, on: attribute.option)
                    .store(in: &cell.disposeBag)
                cell.delegate = composeStatusPollOptionCollectionViewCellDelegate
                ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplacableTextInput: cell.pollOptionView.optionTextField, disposeBag: &cell.disposeBag)
                return cell
            case .pollOptionAppendEntry:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionAppendEntryCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionAppendEntryCollectionViewCell
                cell.delegate = composeStatusNewPollOptionCollectionViewCellDelegate
                return cell
            case .pollExpiresOption(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollExpiresOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollExpiresOptionCollectionViewCell
                cell.durationButton.setTitle(L10n.Scene.Compose.Poll.durationTime(attribute.expiresOption.value.title), for: .normal)
                attribute.expiresOption
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] expiresOption in
                        guard let cell = cell else { return }
                        cell.durationButton.setTitle(L10n.Scene.Compose.Poll.durationTime(expiresOption.title), for: .normal)
                    }
                    .store(in: &cell.disposeBag)
                cell.delegate = composeStatusPollExpiresOptionCollectionViewCellDelegate
                return cell
            }
        }
    }
}

extension ComposeStatusSection {
    
    static func configureStatusContent(
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
            cell.statusView.usernameLabel.text = username.flatMap { "@" + $0 } ?? " "
        }
        .store(in: &cell.disposeBag)
        
        // bind compose content
        cell.composeContent
            .map { $0 as String? }
            .assign(to: \.value, on: attribute.composeContent)
            .store(in: &cell.disposeBag)
    }
    
}

protocol CustomEmojiReplaceableTextInput: AnyObject {
    var inputView: UIView? { get set }
    func reloadInputViews()
    
    // UIKeyInput
    func insertText(_ text: String)
    // UIResponder
    var isFirstResponder: Bool { get }
}

class CustomEmojiReplacableTextInputReference {
    weak var value: CustomEmojiReplaceableTextInput?

    init(value: CustomEmojiReplaceableTextInput? = nil) {
        self.value = value
    }
}

extension TextEditorView: CustomEmojiReplaceableTextInput {
    func insertText(_ text: String) {
        try? updateByReplacing(range: selectedRange, with: text, selectedRange: nil)
    }
    
    public override var isFirstResponder: Bool {
        return isEditing
    }

}
extension UITextField: CustomEmojiReplaceableTextInput { }
extension UITextView: CustomEmojiReplaceableTextInput { }

extension ComposeStatusSection {

    static func configureCustomEmojiPicker(
        viewModel: CustomEmojiPickerInputViewModel?,
        customEmojiReplacableTextInput: CustomEmojiReplaceableTextInput,
        disposeBag: inout Set<AnyCancellable>
    ) {
        guard let viewModel = viewModel else { return }
        viewModel.isCustomEmojiComposing
            .receive(on: DispatchQueue.main)
            .sink { [weak viewModel] isCustomEmojiComposing in
                guard let viewModel = viewModel else { return }
                customEmojiReplacableTextInput.inputView = isCustomEmojiComposing ? viewModel.customEmojiPickerInputView : nil
                customEmojiReplacableTextInput.reloadInputViews()
                viewModel.append(customEmojiReplacableTextInput: customEmojiReplacableTextInput)
            }
            .store(in: &disposeBag)
    }
    
}
