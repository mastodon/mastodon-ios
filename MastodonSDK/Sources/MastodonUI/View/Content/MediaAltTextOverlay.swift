//
//  MediaAltTextOverlay.swift
//  
//
//  Created by Jed Fox on 2022-12-20.
//

import SwiftUI

struct MediaAltTextOverlay: View {
    var altDescription: String?
    
    @State private var showingAlt = false
    @Namespace private var namespace

    var body: some View {
        GeometryReader { geom in
            if let altDescription {
                MediaBadge(isExpanded: $showingAlt) {
                    if showingAlt {
                        Text(altDescription)
                            .font(.caption)
                            .matchedGeometryEffect(id: "background", in: namespace, properties: .position)
                            .transition(
                                .scale(scale: 0.2, anchor: .bottomLeading)
                                .combined(with: .opacity)
                            )
                    } else {
                        Text("ALT")
                            .matchedGeometryEffect(id: "background", in: namespace, properties: .position)
                            .transition(
                                .scale(scale: 3, anchor: .trailing)
                                .combined(with: .opacity)
                            )
                    }
                }
                .animation(.spring(response: 0.3), value: showingAlt)
                .frame(width: geom.size.width, height: geom.size.height, alignment: .bottomLeading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onChange(of: altDescription) { _ in
            showingAlt = false
        }
    }
}

struct MediaAltTextOverlay_Previews: PreviewProvider {
    static var previews: some View {
        MediaAltTextOverlay(altDescription: "Hello, world!")
            .frame(height: 300)
            .background(Color.gray)
            .previewLayout(.sizeThatFits)
    }
}
