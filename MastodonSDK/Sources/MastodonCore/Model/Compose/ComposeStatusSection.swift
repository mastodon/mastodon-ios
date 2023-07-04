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
