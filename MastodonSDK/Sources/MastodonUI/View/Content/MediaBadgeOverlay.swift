//
//  MediaBadgeOverlay.swift
//
//  Created by Jed Fox on 2022-12-20.
//

import SwiftUI

struct MediaBadgeOverlay: View {
    var altDescription: String?
    var isGIF = false
    
    @State private var showingAlt = false
    @State private var space = AnyHashable(UUID())

    var body: some View {
        GeometryReader { geom in
            HStack(alignment: .bottom) {
                if let altDescription {
                    ExpandableMediaBadge("ALT", isExpanded: $showingAlt, in: (geom.size, space)) {
                        Text(altDescription)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if isGIF {
                    MediaBadge("GIF")
                }
            }
            .frame(width: geom.size.width, height: geom.size.height, alignment: .bottomLeading)
            .coordinateSpace(name: space)
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
        MediaBadgeOverlay(altDescription: "Hello, world!")
            .frame(height: 300)
            .background(Color.gray)
            .previewLayout(.sizeThatFits)
    }
}
