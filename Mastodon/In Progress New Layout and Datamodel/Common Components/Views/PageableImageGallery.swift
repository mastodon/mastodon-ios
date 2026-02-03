// Copyright © 2026 Mastodon gGmbH. All rights reserved.
import SwiftUI
import MastodonSDK

@Observable class PageableZoomableViewModel {
    let pageCount: Int
    let dismiss: ()->()
    
    private(set) var focusedPageIndex: Int = 0
    let maxZoom: CGFloat = 4
    let minZoom: CGFloat = 1
    
    private var focusedPageZoomScale: CGFloat = 1
    private var focusedPageInternalOffset: CGSize = .zero
    
    private var focusedPageLiveZoomScale: CGFloat = 1
    private var focusedPageLiveOffset: CGSize = .zero
    
    private var excessScrollDirection: Axis?

    private(set) var pagingPageSize: CGSize = .zero
    private(set) var contentPageSize: CGSize = .zero
    private var focusedPageContentsFittingSize: CGSize = .zero
    
    init(pageCount: Int, dismiss: @escaping ()->()) {
        self.pageCount = pageCount
        self.dismiss = dismiss
    }
    
    func focus(page: Int) {
        resetPageTransforms(liveOnly: false)
        focusedPageIndex = page
    }
    
    func updateContentsFittingSize(_ newSize: CGSize) {
        focusedPageContentsFittingSize = newSize
    }
    
    func updateContentPageSize(_ newSize: CGSize) {
        contentPageSize = newSize
        reclampExistingOffsetAndScale()
    }
    
    func updatePagingPageSize(_ newSize: CGSize) {
        pagingPageSize = newSize
        reclampExistingOffsetAndScale()
    }
    
    func reclampExistingOffsetAndScale() {
        focusedPageZoomScale = clampZoom(focusedPageZoomScale)
        focusedPageInternalOffset = clampOffset(focusedPageInternalOffset)
    }
    
    private func resetPageTransforms(liveOnly: Bool) {
        focusedPageLiveZoomScale = 1
        focusedPageLiveOffset = .zero
        excessScrollDirection = nil
        
        guard !liveOnly else { return }
        focusedPageZoomScale = 1
        focusedPageInternalOffset = .zero
    }
    
    var liveUpdatePageContentsOffset: CGSize {
        focusedPageInternalOffset + focusedPageLiveOffset
    }
    
    var liveUpdatePageContentsScale: CGFloat {
        focusedPageZoomScale * focusedPageLiveZoomScale
    }
    
    func absorbLiveUpdateZoomScaleIntoFocusedPage(liveScale: CGFloat, gestureIsEnded: Bool) {
        let proposedScale = liveScale * focusedPageZoomScale
        let clamped = clampZoom(proposedScale)
        focusedPageLiveZoomScale = clamped / focusedPageZoomScale
        
        if gestureIsEnded  {
            focusedPageZoomScale = clamped
            resetPageTransforms(liveOnly: true)
        }
    }
    
    func absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: CGSize, currentOffset: CGSize, gestureIsEnded: Bool) -> CGSize {
        let proposedOffset = liveOffset + focusedPageInternalOffset
        let clamped = clampOffset(proposedOffset)
       
        let excess = proposedOffset - clamped
        
        if excessScrollDirection == nil {
            excessScrollDirection = abs(liveOffset.width / liveOffset.height) > 1 ? .horizontal : .vertical
        }
        
        let unidirectionalExcessOffset: CGSize
        switch excessScrollDirection {
        case .horizontal:
            unidirectionalExcessOffset = CGSize(width: excess.width, height: 0)
        case .vertical:
            unidirectionalExcessOffset = CGSize(width: 0, height: excess.height)
        case nil:
            unidirectionalExcessOffset = .zero
            assertionFailure("should have been assigned by now")
            break
        }

        if gestureIsEnded {
            focusedPageInternalOffset = clamped
            switch excessScrollDirection {
            case .horizontal:
                let (newFocusedPage, newPagedOffset) = restingPagedOffset(unidirectionalExcessOffset + currentOffset)
                resetPageTransforms(liveOnly: true)
                focusedPageIndex = newFocusedPage
                return newPagedOffset
            case .vertical:
                resetPageTransforms(liveOnly: true)
                return unidirectionalExcessOffset
            case nil:
                assertionFailure("excessScrollDirection should be known as soon as gesture begins")
                return .zero
            }
        } else {
            focusedPageLiveOffset = clamped
            return unidirectionalExcessOffset
        }
    }
    
    private func restingPagedOffset(_ rawOffset: CGSize) -> (Int, CGSize) {
        // find the closest boundary. note that acceptable resting offsets are always <= 0.
        let widthsOffsetNoFurtherThanFinalImage = max(-(CGFloat(pageCount - 1)), (rawOffset.width / pagingPageSize.width).rounded(.toNearestOrEven))
        let widthsOffset = min(widthsOffsetNoFurtherThanFinalImage, 0)
        return (Int(widthsOffset), CGSize(width: pagingPageSize.width * widthsOffset, height: 0))
    }
    
    func clampOffset(_ proposedOffset: CGSize) -> CGSize {
        let baseSize = focusedPageContentsFittingSize
        let scaledSize = CGSize(width: baseSize.width * focusedPageZoomScale, height: baseSize.height * focusedPageZoomScale)
        
        let maxX: CGFloat
        let maxY: CGFloat
        let minX: CGFloat
        let minY: CGFloat
        if scaledSize.width < contentPageSize.width {
            maxX = (contentPageSize.width - scaledSize.width) / 2.0
            minX = maxX
        } else {
            maxX = 0
            minX = contentPageSize.width - scaledSize.width
        }
        if scaledSize.height < contentPageSize.height {
            maxY = (contentPageSize.height - scaledSize.height) / 2.0
            minY = maxY
        } else {
            maxY = 0
            minY = contentPageSize.height - scaledSize.height
        }
        
        let maxOffset = CGSize(width: maxX, height: maxY)
        let minOffset = CGSize(width: minX, height: minY)
        
        let clamped = CGSize(width: max(minOffset.width, min(proposedOffset.width, maxOffset.width)), height: max(minOffset.height, min(proposedOffset.height, maxOffset.height)))
        return clamped
    }
    
    func clampZoom(_ proposedScale: CGFloat) -> CGFloat {
        let clamped = min(maxZoom, max(proposedScale, minZoom))
        return clamped
    }
}

struct PageableImageGallery: View {
    @Environment(ImageGalleryViewModel.self) var galleryViewModel
    @Environment(PageableZoomableViewModel.self) var pageableZoomableViewModel
    @GestureState private var liveScale: CGFloat = 1
    @GestureState private var liveOffset: CGSize = .zero
    @State private var offset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                HStack(spacing: 0) {
                    ForEach(galleryViewModel.imageAttachments, id: \.self.id) { imageInfo in
                        ZoomableImageView(size: geo.size,
                                          index: galleryViewModel.idToIndex[imageInfo.id] ?? 0)
                    }
                }
                .offset(offset + liveOffset)
                
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(pageableZoomableViewModel.liveUpdatePageContentsScale, anchor: .topLeading)
                    .gesture(zoomAndPan) // putting the gesture on a stationary view keeps the motion smooth
            }
            .onAppear() {
                pageableZoomableViewModel.updatePagingPageSize(geo.size)
            }
            .onChange(of: geo.size) { _, newValue in
                pageableZoomableViewModel.updatePagingPageSize(newValue)
            }
        }
        .ignoresSafeArea()
    }
    
    var zoomAndPan: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .updating($liveScale) { value, state, _ in
                    state = value
                    pageableZoomableViewModel.absorbLiveUpdateZoomScaleIntoFocusedPage(liveScale: value, gestureIsEnded: false)
                }
                .onEnded { value in
                    pageableZoomableViewModel.absorbLiveUpdateZoomScaleIntoFocusedPage(liveScale: value, gestureIsEnded: true)
                },
            
            DragGesture()
                .updating($liveOffset) { value, state, _ in
                    let excessOffset = pageableZoomableViewModel.absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: value.translation, currentOffset: offset, gestureIsEnded: false)
                    state = excessOffset
                    print("updating drag \(value.translation)")
                }
                .onEnded { value in
                    let excessOffset = pageableZoomableViewModel.absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: value.translation, currentOffset: offset, gestureIsEnded: true)
                    if abs(excessOffset.height) > (pageableZoomableViewModel.pagingPageSize.height / 2.0) {
                        pageableZoomableViewModel.dismiss()
                    } else {
                        offset = CGSize(width: excessOffset.width, height: excessOffset.height)
                    }
                }
        )
    }
}


struct ZoomableImageView: View {
    @Environment(ImageGalleryViewModel.self) var galleryViewModel
    @Environment(PageableZoomableViewModel.self) var pageableZoomableViewModel
    let size: CGSize
    let index: Int
    
    public init(size: CGSize, index: Int) {
        self.size = size
        self.index = index
    }
    
    private let margin: CGFloat = standardPadding
    
    @State private var fittingSize: CGSize = .zero
    
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
                        .scaleEffect(index == pageableZoomableViewModel.focusedPageIndex
                                     ? pageableZoomableViewModel.liveUpdatePageContentsScale
                                     : 1,
                                     anchor: .topLeading
                        )
                        .offset(index == pageableZoomableViewModel.focusedPageIndex
                                ? pageableZoomableViewModel.liveUpdatePageContentsOffset
                                : .zero
                        )
                        .preference(key: SizePreferenceKey.self,
                                    value: geo.size
                        )
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
        pageableZoomableViewModel.updateContentPageSize(size)
        fittingSize = calculateFittingSize(fromContainerSize: size)
        pageableZoomableViewModel.updateContentsFittingSize(fittingSize)
    }
    
    func calculateFittingSize(fromContainerSize containerSize: CGSize) -> CGSize {
        guard let imageAspect = imageInfo.imageDetails.originalSize?.aspectRatio, let imageSize = imageInfo.imageDetails.originalSize else { return .zero }
        if imageAspect < containerSize.aspectRatio {
            // image is taller.  make the height fit.
            return CGSize(width: containerSize.width * imageAspect, height: containerSize.height)
        } else {
            // image is squatter.  make the width fit.
            let scale = containerSize.width / imageSize.width
            return CGSize(width: containerSize.width, height: imageSize.height * scale)
        }
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
