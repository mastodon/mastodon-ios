//
//  CustomEmojiPickerInputViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-25.
//

import UIKit
import Combine

final class CustomEmojiPickerInputViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    private var customEmojiReplaceableTextInputReferences: [CustomEmojiReplaceableTextInputReference] = []

    // input
    weak var customEmojiPickerInputView: CustomEmojiPickerInputView?
    
    // output
    let isCustomEmojiComposing = CurrentValueSubject<Bool, Never>(false)

}

extension CustomEmojiPickerInputViewModel {
    
    private func removeEmptyReferences() {
        customEmojiReplaceableTextInputReferences.removeAll(where: { element in
            element.value == nil
        })
    }
    
    func append(customEmojiReplaceableTextInput textInput: CustomEmojiReplaceableTextInput) {
        removeEmptyReferences()
        
        let isContains = customEmojiReplaceableTextInputReferences.contains(where: { element in
            element.value === textInput
        })
        guard !isContains else {
            return
        }
        customEmojiReplaceableTextInputReferences.append(CustomEmojiReplaceableTextInputReference(value: textInput))
    }
    
    func insertText(_ text: String) -> CustomEmojiReplaceableTextInputReference? {
        removeEmptyReferences()
        
        for reference in customEmojiReplaceableTextInputReferences {
            guard let textInput = reference.value else { continue }
            guard textInput.isFirstResponder == true else { continue }

            let selectedTextRange = textInput.selectedTextRange
            textInput.insertText(text)

            // due to insert text render as attachment
            // the cursor reset logic not works
            // hack with hard code +2 offset
            assert(text.hasSuffix(": "))
            if text.hasPrefix(":") && text.hasSuffix(": "),
               let selectedTextRange = selectedTextRange,
               let newPosition = textInput.position(from: selectedTextRange.start, offset: 2) {
                let newSelectedTextRange = textInput.textRange(from: newPosition, to: newPosition)
                textInput.selectedTextRange = newSelectedTextRange
            }

            return reference
        }
        
        return nil
    }
    
}

