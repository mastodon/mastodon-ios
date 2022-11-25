//
//  PollOptionTextView.swift
//  
//
//  Created by MainasuK on 2022-5-27.
//

import os.log
import UIKit
import SwiftUI
import Combine
import MastodonCore
import MastodonLocalization

public struct PollOptionTextView: UIViewRepresentable {

    let textView = DeleteBackwardResponseTextView()
    
    @Binding var text: String
    
    let index: Int
    let delegate: DeleteBackwardResponseTextViewRelayDelegate?
    let configurationHandler: (DeleteBackwardResponseTextView) -> Void
    
    public func makeUIView(context: Context) -> DeleteBackwardResponseTextView {
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 6, bottom: 12, right: 8)
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.returnKeyType = .next
        textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16, weight: .regular))
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }
    
    public func updateUIView(_ textView: DeleteBackwardResponseTextView, context: Context) {
        textView.tag = index
        textView.text = text
        textView.placeholder = {
            if index >= 0 {
                return L10n.Scene.Compose.Poll.optionNumber(index + 1)
            } else {
                assertionFailure()
                return ""
            }
        }()
        textView.delegate = context.coordinator
        textView.deleteBackwardDelegate = context.coordinator
        context.coordinator.delegate = delegate
        configurationHandler(textView)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

protocol DeleteBackwardResponseTextViewRelayDelegate: AnyObject {
    func deleteBackwardResponseTextViewDidReturn(_ textView: DeleteBackwardResponseTextView)
    func deleteBackwardResponseTextView(_ textView: DeleteBackwardResponseTextView, textBeforeDelete: String?)
}

extension PollOptionTextView {
    public class Coordinator: NSObject {
        let logger = Logger(subsystem: "DeleteBackwardResponseTextViewRepresentable.Coordinator", category: "Coordinator")
        
        var disposeBag = Set<AnyCancellable>()
        weak var delegate: DeleteBackwardResponseTextViewRelayDelegate?

        let view: PollOptionTextView
        
        init(_ view: PollOptionTextView) {
            self.view = view
            super.init()
            
            NotificationCenter.default.publisher(for: UITextView.textDidChangeNotification, object: view.textView)
                .sink { [weak self] _ in
                    guard let self else { return }
                    self.view.text = view.textView.text ?? ""
                }
                .store(in: &disposeBag)
        }
    }
}

// MARK: - UITextViewDelegate
extension PollOptionTextView.Coordinator: UITextViewDelegate {

    public func textViewShouldReturn(_ textView: UITextView) -> Bool {
        guard let textView = textView as? DeleteBackwardResponseTextView else {
            return true
        }
        delegate?.deleteBackwardResponseTextViewDidReturn(textView)
        return true
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textView = textView as? DeleteBackwardResponseTextView else {
            return true
        }
        if text.contains(where: \.isNewline) {
            delegate?.deleteBackwardResponseTextViewDidReturn(textView)
            return false
        }
        return true
    }
}

extension PollOptionTextView.Coordinator: DeleteBackwardResponseTextViewDelegate {
    public func deleteBackwardResponseTextView(_ textView: DeleteBackwardResponseTextView, textBeforeDelete: String?) {
        delegate?.deleteBackwardResponseTextView(textView, textBeforeDelete: textBeforeDelete)
    }
}
