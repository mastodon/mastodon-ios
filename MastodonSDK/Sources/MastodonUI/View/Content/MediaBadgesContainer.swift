//
//  MediaBadgesContainer.swift
//
//  Created by Jed Fox on 2022-12-20.
//

import SwiftUI

struct MediaBadgesContainer: View {
    var altDescription: String?
    var isGIF = false
    var videoDuration: TimeInterval?
    
    @State private var showingAlt = false
    @State private var space = AnyHashable(UUID())

    // Date.ComponentsFormatStyle does not allow force-enabling minutes unit
    static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = []
        formatter.formattingContext = .standalone
        return formatter
    }()

    var body: some View {
        GeometryReader { geom in
            HStack(alignment: .bottom, spacing: 2) {
                if let altDescription {
                    ExpandableMediaBadge("ALT", isExpanded: $showingAlt, in: (geom.size, space)) {
                        Text(altDescription)
                            .frame(maxHeight: geom.size.height - 16)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if isGIF {
                    MediaBadge("GIF")
                }
                if let videoDuration, let format = Self.formatter.string(from: videoDuration) {
                    MediaBadge(format)
                }
            }
            .frame(width: geom.size.width, height: geom.size.height, alignment: .bottomLeading)
            .coordinateSpace(name: space)
        }
        .padding(8)
        .onChange(of: altDescription) { _ in
            showingAlt = false
        }
    }
}

struct MediaAltTextOverlay_Previews: PreviewProvider {
    static var previews: some View {
        MediaBadgesContainer(altDescription: "Hello, world!")
            .frame(height: 300)
            .background(Color.gray)
            .previewLayout(.sizeThatFits)
    }
}
