//
//  AttachmentDescriptionComposerView.swift
//  
//
//  Created by Jed Fox on 2023-01-06.
//

import SwiftUI

struct AttachmentDescriptionComposerView: View {
    internal init(prompt: String, thumbnail: UIImage, description: Binding<String>) {
        self.prompt = prompt
        self.thumbnail = thumbnail
        self._savedDescription = description
        self._description = State(initialValue: description.wrappedValue)
    }

    let prompt: String
    let thumbnail: UIImage
    @Binding var savedDescription: String

    @Environment(\.dismiss) private var dismiss
    @State private var description: String

    var body: some View {
        NavigationView {
            Form {
                Section(content: {}, footer: {
                    HStack {
                        Spacer(minLength: 0)
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(4)
                        Spacer(minLength: 0)
                    }
                })
                Section(header: Text(prompt)) {
                    TextEditor(text: $description)
                }
            }.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savedDescription = description
                        dismiss()
                    }
                }
            }
        }
    }
}
