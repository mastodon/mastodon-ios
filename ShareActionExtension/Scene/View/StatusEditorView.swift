//
//  StatusEditorView.swift
//
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import UIKit
import SwiftUI
import UITextView_Placeholder

public struct StatusEditorView: UIViewRepresentable {

    @Binding var string: String
    let placeholder: String
    let width: CGFloat
    let attributedString: NSAttributedString
    let keyboardType: UIKeyboardType
    @Binding var viewDidAppear: Bool

    public init(
        string: Binding<String>,
        placeholder: String,
        width: CGFloat,
        attributedString: NSAttributedString,
        keyboardType: UIKeyboardType,
        viewDidAppear: Binding<Bool>
    ) {
        self._string = string
        self.placeholder = placeholder
        self.width = width
        self.attributedString = attributedString
        self.keyboardType = keyboardType
        self._viewDidAppear = viewDidAppear
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.placeholder = placeholder

        textView.isScrollEnabled = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.keyboardType = keyboardType
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear

        textView.translatesAutoresizingMaskIntoConstraints = false
        let widthLayoutConstraint = textView.widthAnchor.constraint(equalToConstant: 100)
        widthLayoutConstraint.priority = .required - 1
        context.coordinator.widthLayoutConstraint = widthLayoutConstraint

        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        // update content
        // textView.attributedText = attributedString
        textView.text = string

        // update layout
        context.coordinator.updateLayout(width: width)

        // set becomeFirstResponder
        if viewDidAppear {
            viewDidAppear = false
            textView.becomeFirstResponder()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: StatusEditorView
        var widthLayoutConstraint: NSLayoutConstraint?

        init(_ parent: StatusEditorView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            parent.string = textView.text
        }

        func updateLayout(width: CGFloat) {
            guard let widthLayoutConstraint = widthLayoutConstraint else { return }
            widthLayoutConstraint.constant = width
            widthLayoutConstraint.isActive = true
        }
    }

}


