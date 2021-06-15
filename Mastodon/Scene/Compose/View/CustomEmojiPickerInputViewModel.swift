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
            guard reference.value?.isFirstResponder == true else { continue }
            reference.value?.insertText(text)
            return reference
        }
        
        return nil
    }
    
}

