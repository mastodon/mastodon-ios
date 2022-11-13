//
//  ComposeContentViewModel+UITextViewDelegate.swift
//  
//
//  Created by MainasuK on 2022/11/13.
//

import os.log
import UIKit

// MARK: - UITextViewDelegate
extension ComposeContentViewModel: UITextViewDelegate {
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        // Note:
        // Xcode warning:
        // Publishing changes from within view updates is not allowed, this will cause undefined behavior.
        //
        // Just ignore the warning and see what will happen…
        switch textView {
        case contentMetaText?.textView:
            isContentEditing = true
        case contentWarningMetaText?.textView:
            isContentWarningEditing = true
        default:
            assertionFailure()
            break
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case contentMetaText?.textView:
            // update model
            guard let metaText = self.contentMetaText else {
                assertionFailure()
                return
            }
            let backedString = metaText.backedString
            logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(backedString)")
            
            // configure auto completion
            setupAutoComplete(for: textView)
            
        case contentWarningMetaText?.textView:
            break
        default:
            assertionFailure()
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        switch textView {
        case contentMetaText?.textView:
            isContentEditing = false
        case contentWarningMetaText?.textView:
            isContentWarningEditing = false
        default:
            assertionFailure()
            break
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView {
        case contentMetaText?.textView:
            if text == " ", let autoCompleteInfo = self.autoCompleteInfo {
                assert(delegate != nil)
                let isHandled = delegate?.composeContentViewModel(self, handleAutoComplete: autoCompleteInfo) ?? false
                return !isHandled
            }
            
            return true
        case contentWarningMetaText?.textView:
            let isReturn = text == "\n"
            if isReturn {
                setContentTextViewFirstResponderIfNeeds()
            }
            return !isReturn
        default:
            assertionFailure()
            return true
        }
    }
    
}

extension ComposeContentViewModel {
    
    func insertContentText(text: String) {
        guard let contentMetaText = self.contentMetaText else { return }
        // FIXME: smart prefix and suffix
        let string = contentMetaText.textStorage.string
        let isEmpty = string.isEmpty
        let hasPrefix = string.hasPrefix(" ")
        if hasPrefix || isEmpty {
            contentMetaText.textView.insertText(text)
        } else {
            contentMetaText.textView.insertText(" " + text)
        }
    }
    
    func setContentTextViewFirstResponderIfNeeds() {
        guard let contentMetaText = self.contentMetaText else { return }
        guard !contentMetaText.textView.isFirstResponder else { return }
        contentMetaText.textView.becomeFirstResponder()
    }
    
    func setContentWarningTextViewFirstResponderIfNeeds() {
        guard let contentWarningMetaText = self.contentWarningMetaText else { return }
        guard !contentWarningMetaText.textView.isFirstResponder else { return }
        contentWarningMetaText.textView.becomeFirstResponder()
    }
    
}

extension ComposeContentViewModel {
    
    private func setupAutoComplete(for textView: UITextView) {
        guard var autoCompletion = ComposeContentViewModel.scanAutoCompleteInfo(textView: textView) else {
            self.autoCompleteInfo = nil
            return
        }
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: auto complete %s (%s)", ((#file as NSString).lastPathComponent), #line, #function, String(autoCompletion.toHighlightEndString), String(autoCompletion.toCursorString))
        
        // get layout text bounding rect
        var glyphRange = NSRange()
        textView.layoutManager.characterRange(forGlyphRange: NSRange(autoCompletion.toCursorRange, in: textView.text), actualGlyphRange: &glyphRange)
        let textContainer = textView.layoutManager.textContainers[0]
        let textBoundingRect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        let retryLayoutTimes = autoCompleteRetryLayoutTimes
        guard textBoundingRect.size != .zero else {
            autoCompleteRetryLayoutTimes += 1
            // avoid infinite loop
            guard retryLayoutTimes < 3 else { return }
            // needs retry calculate layout when the rect position changing
            DispatchQueue.main.async {
                self.setupAutoComplete(for: textView)
            }
            return
        }
        autoCompleteRetryLayoutTimes = 0
        
        // get symbol bounding rect
        textView.layoutManager.characterRange(forGlyphRange: NSRange(autoCompletion.symbolRange, in: textView.text), actualGlyphRange: &glyphRange)
        let symbolBoundingRect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // set bounding rect and trigger layout
        autoCompletion.textBoundingRect = textBoundingRect
        autoCompletion.symbolBoundingRect = symbolBoundingRect
        autoCompleteInfo = autoCompletion
    }
    
    private static func scanAutoCompleteInfo(textView: UITextView) -> AutoCompleteInfo? {
        guard let text = textView.text,
              textView.selectedRange.location > 0, !text.isEmpty,
              let selectedRange = Range(textView.selectedRange, in: text) else {
            return nil
        }
        let cursorIndex = selectedRange.upperBound
        let _highlightStartIndex: String.Index? = {
            var index = text.index(before: cursorIndex)
            while index > text.startIndex {
                let char = text[index]
                if char == "@" || char == "#" || char == ":" {
                    return index
                }
                index = text.index(before: index)
            }
            assert(index == text.startIndex)
            let char = text[index]
            if char == "@" || char == "#" || char == ":" {
                return index
            } else {
                return nil
            }
        }()
        
        guard let highlightStartIndex = _highlightStartIndex else { return nil }
        let scanRange = NSRange(highlightStartIndex..<text.endIndex, in: text)
        
        guard let match = text.firstMatch(pattern: MastodonRegex.autoCompletePattern, options: [], range: scanRange) else { return nil }
        guard let matchRange = Range(match.range(at: 0), in: text) else { return nil }
        let matchStartIndex = matchRange.lowerBound
        let matchEndIndex = matchRange.upperBound
        
        guard matchStartIndex == highlightStartIndex, matchEndIndex >= cursorIndex else { return nil }
        let symbolRange = highlightStartIndex..<text.index(after: highlightStartIndex)
        let symbolString = text[symbolRange]
        let toCursorRange = highlightStartIndex..<cursorIndex
        let toCursorString = text[toCursorRange]
        let toHighlightEndRange = matchStartIndex..<matchEndIndex
        let toHighlightEndString = text[toHighlightEndRange]
        
        let inputText = toHighlightEndString
        let autoCompleteInfo = AutoCompleteInfo(
            inputText: inputText,
            symbolRange: symbolRange,
            symbolString: symbolString,
            toCursorRange: toCursorRange,
            toCursorString: toCursorString,
            toHighlightEndRange: toHighlightEndRange,
            toHighlightEndString: toHighlightEndString
        )
        return autoCompleteInfo
    }
    
}
