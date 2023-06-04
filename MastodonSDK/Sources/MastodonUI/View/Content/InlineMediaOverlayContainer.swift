//
//  InlineMediaOverlayContainer.swift
//
//  Created by Jed Fox on 2022-12-20.
//

import SwiftUI

struct InlineMediaOverlayContainer: View {
    var altDescription: String?
    var mediaType: MediaType = .image
    var showDuration = false
    var mediaDuration: TimeInterval?

    enum MediaType {
        case image
        case gif
        case video
    }

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
                if mediaType == .gif {
                    MediaBadge("GIF")
                }
                if showDuration {
                    if let mediaDuration, let format = Self.formatter.string(from: mediaDuration) {
                        MediaBadge(format)
                            .monospacedDigit()
                    } else {
                        MediaBadge("--:--")
                    }
                }
            }
            .frame(width: geom.size.width, height: geom.size.height, alignment: .bottomLeading)
            .coordinateSpace(name: space)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay {
            if mediaType == .video {
                  Image(systemName: "play.circle.fill")
                     .font(.system(size: 54))
                     .foregroundColor(.white)
                     .shadow(color: .black.opacity(0.5), radius: 32, x: 0, y: 0)
                     .background(alignment: .center) {
                         Circle()
                             .fill(.ultraThinMaterial)
                             .frame(width: 40, height: 40)
                             .colorScheme(.light)
                     }
            }
        }
        .onChange(of: altDescription) { _ in
            showingAlt = false
        }
    }
}

struct MediaAltTextOverlay_Previews: PreviewProvider {
    static var previews: some View {
        InlineMediaOverlayContainer(altDescription: "Hello, world!")
            .frame(height: 300)
            .background(Color.gray)
            .previewLayout(.sizeThatFits)
    }
}
