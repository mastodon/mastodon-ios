//
//  TextEditorView.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import UIKit
import SwiftUI

public struct TextEditorView: UIViewRepresentable {

    @Binding var string: String

    let width: CGFloat
    let attributedString: NSAttributedString

    public init(
        string: Binding<String>,
        width: CGFloat,
        attributedString: NSAttributedString
    ) {
        self._string = string
        self.width = width
        self.attributedString = attributedString
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(frame: .zero)

        textView.isScrollEnabled = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label

        textView.delegate = context.coordinator

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
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorView
        var widthLayoutConstraint: NSLayoutConstraint?

        init(_ parent: TextEditorView) {
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


