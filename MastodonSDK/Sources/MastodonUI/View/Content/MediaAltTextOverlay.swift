//
//  MediaAltTextOverlay.swift
//  
//
//  Created by Jed Fox on 2022-12-20.
//

import SwiftUI

@available(iOS 15.0, *)
struct MediaAltTextOverlay: View {
    var altDescription: String?
    
    @State private var showingAlt = false

    var body: some View {
        HStack {
            VStack {
                Spacer(minLength: 0)
                if altDescription != nil {
                    Button("ALT") {}
                        .buttonStyle(AltButtonStyle())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onChange(of: altDescription) { _ in
            showingAlt = false
        }
    }
}

@available(iOS 15.0, *)
private struct AltButtonStyle: ButtonStyle {
    @Environment(\.pixelLength) private var pixelLength
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.85))
            .cornerRadius(4)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .overlay(
                .white.opacity(0.4),
                in: RoundedRectangle(cornerRadius: 4)
                    .inset(by: -0.5)
                    .stroke(lineWidth: 0.5)
            )
    }
}

@available(iOS 15.0, *)
struct MediaAltTextOverlay_Previews: PreviewProvider {
    static var previews: some View {
        MediaAltTextOverlay(altDescription: nil)
        MediaAltTextOverlay(altDescription: "Hello, world!")
    }
}
