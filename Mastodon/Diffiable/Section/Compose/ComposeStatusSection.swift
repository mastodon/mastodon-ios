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
import MetaTextKit
import MastodonMeta
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

    static func configureStatusContent(
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
        Publishers.CombineLatest3(
            attribute.displayName,
            attribute.emojiDict,
            attribute.username.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { displayName, emojiDict, username in
            cell.statusView.nameLabel.configure(content: displayName ?? " ", emojiDict: emojiDict)
            cell.statusView.usernameLabel.text = username.flatMap { "@" + $0 } ?? " "
        }
        .store(in: &cell.disposeBag)
    }
    
}

protocol CustomEmojiReplaceableTextInput: UITextInput & UIResponder {
    var inputView: UIView? { get set }
}

class CustomEmojiReplaceableTextInputReference {
    weak var value: CustomEmojiReplaceableTextInput?

    init(value: CustomEmojiReplaceableTextInput? = nil) {
        self.value = value
    }
}

extension UITextField: CustomEmojiReplaceableTextInput { }
extension UITextView: CustomEmojiReplaceableTextInput { }

extension ComposeStatusSection {

    static func configureCustomEmojiPicker(
        viewModel: CustomEmojiPickerInputViewModel?,
        customEmojiReplaceableTextInput: CustomEmojiReplaceableTextInput,
        disposeBag: inout Set<AnyCancellable>
    ) {
        guard let viewModel = viewModel else { return }
        viewModel.isCustomEmojiComposing
            .receive(on: DispatchQueue.main)
            .sink { [weak viewModel] isCustomEmojiComposing in
                guard let viewModel = viewModel else { return }
                customEmojiReplaceableTextInput.inputView = isCustomEmojiComposing ? viewModel.customEmojiPickerInputView : nil
                customEmojiReplaceableTextInput.reloadInputViews()
                viewModel.append(customEmojiReplaceableTextInput: customEmojiReplaceableTextInput)
            }
            .store(in: &disposeBag)
    }
    
}
