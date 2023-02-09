//
//  AttachmentDescriptionComposerView.swift
//  
//
//  Created by Jed Fox on 2023-01-06.
//

import SwiftUI
import VisionKit

struct AttachmentDescriptionComposerView: View {
    internal init(prompt: String, thumbnail: UIImage, description: Binding<String>) {
        self.prompt = prompt
        self.thumbnail = thumbnail
        self._savedDescription = description
        self._description = State(initialValue: description.wrappedValue)
        self._analysis = StateObject(wrappedValue: ImageAnalyzerModel(image: thumbnail))
    }

    let prompt: String
    let thumbnail: UIImage
    @Binding var savedDescription: String

    @Environment(\.dismiss) private var dismiss
    @State private var description: String
    @StateObject private var analysis: ImageAnalyzerModel

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
                            .overlay(alignment: .bottomTrailing) {
                                if let transcript = analysis.transcript, !description.contains(transcript) {
                                    Button {
                                        if description.isEmpty {
                                            description = transcript
                                        } else {
                                            description += "\n\n" + transcript
                                        }
                                    } label: {
                                        Label("Use Detected Text", systemImage: "text.viewfinder")
                                        .foregroundColor(.black)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .buttonBorderShape(.capsule)
                                    .tint(.white)
                                    .padding()
                                    .transition(.opacity)
                                }
                            }
                            .animation(.default, value: analysis.transcript)
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

@MainActor private class ImageAnalyzerModel: ObservableObject {
    let image: UIImage
    
    @Published var transcript: String?
    
    private var analysisTask: Task<Void, Error>?

    init(image: UIImage) {
        self.image = image
        
        guard #available(iOS 16, *), ImageAnalyzer.isSupported else { return }
        let analyzer = ImageAnalyzer()
        analysisTask = Task.detached(priority: .high) { [weak self] in
            let result = try await analyzer.analyze(image, configuration: .init(.text))
            await MainActor.run { [self] in
                self?.transcript = result.transcript
            }
        }
    }
    
    deinit {
        analysisTask?.cancel()
    }
}
