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
    @Namespace private var namespace

    var body: some View {
        GeometryReader { geom in
            ZStack {
                if let altDescription {
                    if showingAlt {
                        HStack(alignment: .top) {
                            Text(altDescription)
                            Spacer()
                            Button(action: { showingAlt = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .transition(.scale(scale: 0.1, anchor: .bottomLeading))
                        .padding(8)
                        .frame(width: geom.size.width)
                        .fixedSize()
                        .matchedGeometryEffect(id: "background", in: namespace)
                    } else {
                        Button("ALT") { showingAlt = true }
                            .fixedSize()
                            .buttonStyle(AltButtonStyle())
                            .matchedGeometryEffect(id: "background", in: namespace)
                    }
                }
            }
            .foregroundColor(.white)
            .tint(.white)
            .background(Color.black.opacity(0.85))
            .cornerRadius(4)
            .overlay(
                .white.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 4)
                    .inset(by: -0.5)
                    .stroke(lineWidth: 0.5)
            )
            .animation(.spring(response: 0.25), value: showingAlt)
            .frame(width: geom.size.width, height: geom.size.height, alignment: .bottomLeading)
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

@available(iOS 15.0, *)
struct MediaAltTextOverlay_Previews: PreviewProvider {
    static var previews: some View {
        MediaAltTextOverlay(altDescription: "Hello, world!")
            .frame(height: 300)
            .background(Color.gray)
            .previewLayout(.sizeThatFits)
    }
}
