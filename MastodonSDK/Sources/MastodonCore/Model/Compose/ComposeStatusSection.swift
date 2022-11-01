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

public enum ComposeStatusSection: Equatable, Hashable {
    case replyTo
    case status
    case attachment
    case poll
}

extension ComposeStatusSection {

//    static func configure(
//        cell: ComposeStatusContentTableViewCell,
//        attribute: ComposeStatusItem.ComposeStatusAttribute
//    ) {
//        cell.prepa
//        // set avatar
//        attribute.avatarURL
//            .receive(on: DispatchQueue.main)
//            .sink { avatarURL in
//                cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: avatarURL))
//            }
//            .store(in: &cell.disposeBag)
//        // set display name and username
//        Publishers.CombineLatest3(
//            attribute.displayName,
//            attribute.emojiMeta,
//            attribute.username
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { displayName, emojiMeta, username in
//            do {
//                let mastodonContent = MastodonContent(content: displayName ?? " ", emojis: emojiMeta)
//                let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
//                cell.statusView.nameLabel.configure(content: metaContent)
//            } catch {
//                let metaContent = PlaintextMetaContent(string: " ")
//                cell.statusView.nameLabel.configure(content: metaContent)
//            }
//            cell.statusView.usernameLabel.text = username.flatMap { "@" + $0 } ?? " "
//        }
//        .store(in: &cell.disposeBag)
//    }
    
}

public protocol CustomEmojiReplaceableTextInput: UITextInput & UIResponder {
    var inputView: UIView? { get set }
}

public class CustomEmojiReplaceableTextInputReference {
    public weak var value: CustomEmojiReplaceableTextInput?

    public init(value: CustomEmojiReplaceableTextInput? = nil) {
        self.value = value
    }
}

extension UITextField: CustomEmojiReplaceableTextInput { }
extension UITextView: CustomEmojiReplaceableTextInput { }

extension ComposeStatusSection {

//    static func configureCustomEmojiPicker(
//        viewModel: CustomEmojiPickerInputViewModel?,
//        customEmojiReplaceableTextInput: CustomEmojiReplaceableTextInput,
//        disposeBag: inout Set<AnyCancellable>
//    ) {
//        guard let viewModel = viewModel else { return }
//        viewModel.isCustomEmojiComposing
//            .receive(on: DispatchQueue.main)
//            .sink { [weak viewModel] isCustomEmojiComposing in
//                guard let viewModel = viewModel else { return }
//                customEmojiReplaceableTextInput.inputView = isCustomEmojiComposing ? viewModel.customEmojiPickerInputView : nil
//                customEmojiReplaceableTextInput.reloadInputViews()
//                viewModel.append(customEmojiReplaceableTextInput: customEmojiReplaceableTextInput)
//            }
//            .store(in: &disposeBag)
//    }
    
}
