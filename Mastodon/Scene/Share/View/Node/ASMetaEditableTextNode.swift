//
//  ASMetaEditableTextNode.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-20.
//

#if ASDK

import UIKit
import AsyncDisplayKit

protocol ASMetaEditableTextNodeDelegate: AnyObject {
    func metaEditableTextNode(_ textNode: ASMetaEditableTextNode, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
}

final class ASMetaEditableTextNode: ASEditableTextNode, UITextViewDelegate {
    weak var metaEditableTextNodeDelegate: ASMetaEditableTextNodeDelegate?

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return metaEditableTextNodeDelegate?.metaEditableTextNode(self, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? false
    }
}

#endif
