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

    var body: some View {
        GeometryReader { geom in
            if let altDescription {
                ExpandableMediaBadge("ALT", isExpanded: $showingAlt) {
                    Text(altDescription)
                }
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
