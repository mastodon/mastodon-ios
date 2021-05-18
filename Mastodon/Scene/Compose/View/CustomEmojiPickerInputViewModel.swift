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
    
    private var customEmojiReplacableTextInputReferences: [CustomEmojiReplacableTextInputReference] = []

    // input
    weak var customEmojiPickerInputView: CustomEmojiPickerInputView?
    
    // output
    let isCustomEmojiComposing = CurrentValueSubject<Bool, Never>(false)

}

extension CustomEmojiPickerInputViewModel {
    
    private func removeEmptyReferences() {
        customEmojiReplacableTextInputReferences.removeAll(where: { element in
            element.value == nil
        })
    }
    
    func append(customEmojiReplacableTextInput textInput: CustomEmojiReplaceableTextInput) {
        removeEmptyReferences()
        
        let isContains = customEmojiReplacableTextInputReferences.contains(where: { element in
            element.value === textInput
        })
        guard !isContains else {
            return
        }
        customEmojiReplacableTextInputReferences.append(CustomEmojiReplacableTextInputReference(value: textInput))
    }
    
    func insertText(_ text: String) -> CustomEmojiReplacableTextInputReference? {
        removeEmptyReferences()
        
        for reference in customEmojiReplacableTextInputReferences {
            guard reference.value?.isFirstResponder == true else { continue }
            reference.value?.insertText(text)
            return reference
        }
        
        return nil
    }
    
}

