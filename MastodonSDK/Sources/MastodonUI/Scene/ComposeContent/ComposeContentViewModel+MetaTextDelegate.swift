//
//  ComposeContentViewModel+MetaTextDelegate.swift
//  
//
//  Created by MainasuK on 2022/10/28.
//

import os.log
import UIKit
import MetaTextKit
import TwitterMeta
import MastodonMeta

// MARK: - MetaTextDelegate
extension ComposeContentViewModel: MetaTextDelegate {
    
    public enum MetaTextViewKind: Int {
        case none
        case content
        case contentWarning
    }
    
    public func metaText(
        _ metaText: MetaText,
        processEditing textStorage: MetaTextStorage
    ) -> MetaContent? {
        let kind = MetaTextViewKind(rawValue: metaText.textView.tag) ?? .none
        
        switch kind {
        case .none:
            assertionFailure()
            return nil
            
        case .content:
            let textInput = textStorage.string
            self.content = textInput
            
            let content = MastodonContent(
                content: textInput,
                emojis: [:] // customEmojiViewModel?.emojis.value.asDictionary ?? [:]
            )
            let metaContent = MastodonMetaContent.convert(text: content)
            return metaContent
            
        case .contentWarning:
            let textInput = textStorage.string.replacingOccurrences(of: "\n", with: " ")
            self.contentWarning = textInput
            
            let content = MastodonContent(
                content: textInput,
                emojis: [:] // customEmojiViewModel?.emojis.value.asDictionary ?? [:]
            )
            let metaContent = MastodonMetaContent.convert(text: content)
            return metaContent
        }
    }
}
