//
//  ContentWarningEditorView.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-19.
//

import SwiftUI
import Introspect

struct ContentWarningEditorView: View {

    @Binding var contentWarningContent: String
    let placeholder: String
    let spacing: CGFloat = 11

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 30, weight: .regular))
            Text(contentWarningContent.isEmpty ? " " : contentWarningContent)
                .opacity(0)
                .padding(.all, 8)
                .frame(maxWidth: .infinity)
                .overlay(
                    TextEditor(text: $contentWarningContent)
                        .introspectTextView { textView in
                            textView.backgroundColor = .clear
                            textView.placeholder = placeholder
                        }
                )
        }
    }
}

struct ContentWarningEditorView_Previews: PreviewProvider {

    @State static var content = ""

    static var previews: some View {
        ContentWarningEditorView(
            contentWarningContent: $content,
            placeholder: "Write an accurate warning here..."
        )
        .previewLayout(.fixed(width: 375, height: 100))
    }
}

