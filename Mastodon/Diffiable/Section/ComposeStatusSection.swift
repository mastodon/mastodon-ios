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
        customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel,
        textEditorViewTextAttributesDelegate: TextEditorViewTextAttributesDelegate,
        composeStatusAttachmentTableViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate,
        composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate,
        composeStatusNewPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate,
        composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate
    ) -> UICollectionViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [
            weak customEmojiPickerInputViewModel,
            weak textEditorViewTextAttributesDelegate,
            weak composeStatusAttachmentTableViewCellDelegate,
            weak composeStatusPollOptionCollectionViewCellDelegate,
            weak composeStatusNewPollOptionCollectionViewCellDelegate,
            weak composeStatusPollExpiresOptionCollectionViewCellDelegate
        ] collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .replyTo(let repliedToStatusObjectID):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeRepliedToStatusContentCollectionViewCell.self), for: indexPath) as! ComposeRepliedToStatusContentCollectionViewCell
                return cell
            case .input(let replyToStatusObjectID, let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusContentCollectionViewCell.self), for: indexPath) as! ComposeStatusContentCollectionViewCell
                cell.textEditorView.text = attribute.composeContent.value ?? ""
                managedObjectContext.perform {
                    guard let replyToStatusObjectID = replyToStatusObjectID,
                          let replyTo = managedObjectContext.object(with: replyToStatusObjectID) as? Status else {
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
                attribute.isContentWarningComposing
                    .receive(on: DispatchQueue.main)
                    .sink { isContentWarningComposing in
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
                    .sink { text in
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
            case .pollOption(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionCollectionViewCell
                cell.pollOptionView.optionTextField.text = attribute.option.value
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
                    .sink { expiresOption in
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

protocol CustomEmojiReplacableTextInput: AnyObject {
    var inputView: UIView? { get set }
    func reloadInputViews()
    
    // UIKeyInput
    func insertText(_ text: String)
    // UIResponder
    var isFirstResponder: Bool { get }
}

class CustomEmojiReplacableTextInputReference {
    weak var value: CustomEmojiReplacableTextInput?

    init(value: CustomEmojiReplacableTextInput? = nil) {
        self.value = value
    }
}

extension TextEditorView: CustomEmojiReplacableTextInput {
    func insertText(_ text: String) {
        try? updateByReplacing(range: selectedRange, with: text, selectedRange: nil)
    }
    
    public override var isFirstResponder: Bool {
        return isEditing
    }

}
extension UITextField: CustomEmojiReplacableTextInput { }
extension UITextView: CustomEmojiReplacableTextInput { }

extension ComposeStatusSection {

    static func configureCustomEmojiPicker(
        viewModel: CustomEmojiPickerInputViewModel?,
        customEmojiReplacableTextInput: CustomEmojiReplacableTextInput,
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
