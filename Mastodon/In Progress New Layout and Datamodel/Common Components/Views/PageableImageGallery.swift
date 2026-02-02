// Copyright © 2026 Mastodon gGmbH. All rights reserved.
import SwiftUI
import MastodonSDK

struct PageableImageGallery: View {
    @Environment(ImageGalleryViewModel.self) var galleryViewModel
    @State private var offset: CGSize = .zero
    @State private var liveOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            HStack {
                ForEach(galleryViewModel.imageAttachments, id: \.self.id) { imageInfo in
                    ZoomableImageView(size: geo.size,
                                      index: galleryViewModel.idToIndex[imageInfo.id] ?? 0,
                                      updateExcessGestureOffset: { additionalOffset in
                        liveOffset = additionalOffset + liveOffset
                    },
                                      dragGestureDidEnd: { finalAdditionalOffset in
                        let finalOffset = offset + liveOffset + finalAdditionalOffset
                        liveOffset = .zero
                        // find the closest boundary. note that acceptable resting offsets are always <= 0.
                        let widthsOffsetNoFurtherThanFinalImage = max(-(CGFloat(galleryViewModel.imageAttachments.count) - 1), (finalOffset.width / geo.size.width).rounded(.toNearestOrEven))
                        let widthsOffset = min(widthsOffsetNoFurtherThanFinalImage, 0)
                        offset = CGSize(width: geo.size.width * widthsOffset, height: 0)
                    }
                    )
                }
            }
        }
        .ignoresSafeArea()
        .offset(offset + liveOffset)
    }
}


struct ZoomableImageView: View {
    @Environment(ImageGalleryViewModel.self) var galleryViewModel
    let size: CGSize
    let index: Int
    let updateExcessGestureOffset: (CGSize)->()
    let dragGestureDidEnd: (CGSize)->()
    
    public init(size: CGSize, index: Int, updateExcessGestureOffset: @escaping (CGSize)->(), dragGestureDidEnd: @escaping (CGSize)->()) {
        self.size = size
        self.index = index
        self.updateExcessGestureOffset = updateExcessGestureOffset
        self.dragGestureDidEnd = dragGestureDidEnd
    }
    
    private let maxScale: CGFloat = 4
    private var minScale: CGFloat = 1
    private let margin: CGFloat = standardPadding
    
    @State private var geoSize: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var fittingSize: CGSize = .zero
    
    @GestureState private var currentGestureScale: CGFloat = 1
    @GestureState private var currentGestureOffset: CGSize = .zero
    
    var liveUpdateOffset: CGSize {
        let proposed = CGSize(
            width: offset.width + currentGestureOffset.width,
            height: offset.height + currentGestureOffset.height
        )
        return clampOffset(proposed)
    }
    
    var liveUpdateScale: CGFloat {
        let proposed = scale * currentGestureScale
        return clampZoom(proposed)
    }
    
    var imageInfo: MastodonImageAttachment {
        galleryViewModel.imageAttachments[index]
    }
    
    var body: some View {
        ZStack {
            Color.dimmingBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            GeometryReader { geo in
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                    Color.clear
                        .frame(width: geo.size.width, height: geo.size.height)
                    BlurhashImageView(url: imageInfo.basicData.fullsizeUrl, imageDetails: imageInfo.imageDetails, blurhash: galleryViewModel.blurhashes[imageInfo.basicData.id])
                        .frame(width: fittingSize.width, height: fittingSize.height)
                        .scaleEffect(liveUpdateScale, anchor: .topLeading)
                        .offset(
                            liveUpdateOffset
                        )
                        .gesture(zoomAndPan)
                        .preference(key: SizePreferenceKey.self,
                                    value: geo.size)
                        .onPreferenceChange(SizePreferenceKey.self) { newValue in
                            updateGeometry(fromSize: newValue)
                        }
                        .onAppear() {
                            updateGeometry(fromSize: geo.size)
                        }
                }
            }
            .padding()
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
    
    func updateGeometry(fromSize size: CGSize) {
        geoSize = size
        offset = clampOffset(offset)
        scale = clampZoom(scale)
        fittingSize = calculateFittingSize(fromContainerSize: size)
    }
    
    func clampOffset(_ proposedOffset: CGSize) -> CGSize {
        let baseSize = fittingSize
        let scaledSize = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)

        let maxX: CGFloat
        let maxY: CGFloat
        let minX: CGFloat
        let minY: CGFloat
        if scaledSize.width < geoSize.width {
            maxX = (geoSize.width - scaledSize.width) / 2.0
            minX = maxX
        } else {
            maxX = 0
            minX = geoSize.width - scaledSize.width
        }
        if scaledSize.height < geoSize.height {
            maxY = (geoSize.height - scaledSize.height) / 2.0
            minY = maxY
        } else {
            maxY = 0
            minY = geoSize.height - scaledSize.height
        }
        
        let maxOffset = CGSize(width: maxX, height: maxY)
        let minOffset = CGSize(width: minX, height: minY)
        
        let clamped = CGSize(width: max(minOffset.width, min(proposedOffset.width, maxOffset.width)), height: max(minOffset.height, min(proposedOffset.height, maxOffset.height)))
        return clamped
    }
    
    func clampZoom(_ proposedScale: CGFloat) -> CGFloat {
        let clamped = min(maxScale, max(proposedScale, minScale))
        return clamped
    }
    
    func calculateFittingSize(fromContainerSize containerSize: CGSize) -> CGSize {
        guard let imageAspect = imageInfo.imageDetails.originalSize?.aspectRatio, let imageSize = imageInfo.imageDetails.originalSize else { return .zero }
        if imageAspect < geoSize.aspectRatio {
            // image is taller.  make the height fit.
            return CGSize(width: geoSize.width * imageAspect, height: geoSize.height)
        } else {
            // image is squatter.  make the width fit.
            let scale = geoSize.width / imageSize.width
            return CGSize(width: geoSize.width, height: imageSize.height * scale)
        }
    }
    
    var zoomAndPan: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .updating($currentGestureScale) { value, state, _ in
                    state = value
                }
                .onEnded { value in
                    let proposedScale = scale * value
                    scale = clampZoom(proposedScale)
                },
            
            DragGesture()
                .updating($currentGestureOffset) { value, state, _ in
                    state = value.translation
                    let clamped = clampOffset(value.translation)
                    updateExcessGestureOffset(value.translation - clamped)
                }
                .onEnded { value in
                    let proposedOffset = offset + value.translation
                    offset = clampOffset(proposedOffset)
                    let clamped = clampOffset(value.translation)
                    dragGestureDidEnd(value.translation - clamped)
                }
        )
    }
}

extension CGSize {
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}
