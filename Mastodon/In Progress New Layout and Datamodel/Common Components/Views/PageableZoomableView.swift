// Copyright © 2026 Mastodon gGmbH. All rights reserved.
import SwiftUI
import MastodonSDK

@MainActor
@Observable class PageableZoomableViewModel {
    let pageCount: Int
    var dismiss: ()->()
    
    var focusedPageIndex: Int = 0
    let maxZoom: CGFloat = 4
    let minZoom: CGFloat = 1
    
    private var zoomScales: [CGFloat]
    private var internalOffsets: [CGSize]
    private var focusedPageContentsFittingSizes: [CGSize]
    
    private var focusedPageLiveZoomScale: CGFloat = 1
    private var focusedPageLiveOffset: CGSize = .zero
    public var focusedPageLiveZoomAnchor: UnitPoint?
    
    private var excessScrollDirection: Axis?

    private(set) var pagingPageSize: CGSize = .zero
    private(set) var contentPageSizes: [CGSize]
    private(set) var contentsFittingSizes: [CGSize]
    
    init(pageCount: Int, focusedPage: Int, dismiss: @escaping ()->()) {
        self.pageCount = pageCount
        self.dismiss = dismiss
        self.zoomScales = Array(repeating: 1, count: pageCount)
        self.internalOffsets = Array(repeating: .zero, count: pageCount)
        self.contentPageSizes = Array(repeating: .zero, count: pageCount)
        self.contentsFittingSizes = Array(repeating: .zero, count: pageCount)
        self.focusedPageContentsFittingSizes = Array(repeating: .zero, count: pageCount)
        self.focusedPageIndex = focusedPage
    }
    
    func focus(page: Int) {
        resetLiveTransforms()
        focusedPageIndex = page
    }
    
    func updateContentsFittingSize(_ index: Int, newSize: CGSize) {
        contentsFittingSizes[index] = newSize
    }
    
    func updateContentPageSize(_ index: Int, newSize: CGSize) {
        contentPageSizes[index] = newSize
        reclampExistingOffsetsAndScales()
    }
    
    func updatePagingPageSizeAndReturnNewFocusedPageOffset(_ newSize: CGSize) -> CGSize {
        pagingPageSize = newSize
        reclampExistingOffsetsAndScales()
        return CGSize(width: -pagingPageSize.width * CGFloat(focusedPageIndex), height: 0)
    }
    
    func reclampExistingOffsetsAndScales() {
        for (i, scale) in zoomScales.enumerated() {
            zoomScales[i] = clampZoom(scale)
        }
        for (i, offset) in internalOffsets.enumerated() {
            internalOffsets[i] = clampOffset(i, proposedOffset: offset, scale: zoomScales[i])
        }
    }
    
    private func resetLiveTransforms() {
        focusedPageLiveZoomScale = 1
        focusedPageLiveOffset = .zero
        focusedPageLiveZoomAnchor = nil
        excessScrollDirection = nil
    }
    
    func liveUpdatePageContentsOffset(_ index: Int) -> CGSize {
        if index == focusedPageIndex {
            return internalOffsets[index] + focusedPageLiveOffset
        } else {
            return internalOffsets[index]
        }
    }
    
    func liveUpdatePageContentsAdditionalScale(_ index: Int) -> CGFloat {
        return index == focusedPageIndex ? focusedPageLiveZoomScale : 1
    }
    
    func restingPageContentsScale(_ index: Int) -> CGFloat {
        return zoomScales[index]
    }
    
    func liveUpdateScaleAnchor(_ index: Int) -> UnitPoint {
        if index == focusedPageIndex {
            return focusedPageLiveZoomAnchor ?? .center
        } else {
            return .center
        }
    }
    
    func absorbLiveUpdateZoomScaleIntoFocusedPage(liveScale: CGFloat, gestureAnchor: UnitPoint, currentOffset: CGSize, gestureIsEnded: Bool) {
        let proposedScale = liveScale * zoomScales[focusedPageIndex]
        let clampedScale = clampZoom(proposedScale)
        focusedPageLiveZoomScale = clampedScale / zoomScales[focusedPageIndex]
        
        if gestureIsEnded  {
            // adjust the offset to absorb the shift caused by the scale
            let anchorRespectingOffset = focusedPageOffsetAbsorbing(additionalScale: focusedPageLiveZoomScale, atGestureViewAnchor: gestureAnchor)
            
            zoomScales[focusedPageIndex] = clampedScale
            resetLiveTransforms()
            let clampedOffset = clampOffset(focusedPageIndex, proposedOffset: anchorRespectingOffset, scale: clampedScale)
            internalOffsets[focusedPageIndex] = anchorRespectingOffset
            withAnimation {
                internalOffsets[focusedPageIndex] = clampedOffset
            }
        } else {
            // set the anchor of the live scale effect
            focusedPageLiveZoomAnchor = focusedPageContentAnchorPoint(forGestureViewAnchorPoint: gestureAnchor)
        }
    }
    
    func focusedPageOffsetAbsorbing(additionalScale: CGFloat, atGestureViewAnchor gestureAnchor: UnitPoint) -> CGSize {
        // find the actual location of the anchor in the current scaled content view
        let anchorLocationInScaledContentView = locationInScaledContentView(ofGestureAnchorPoint: gestureAnchor)
        // find the distance from that location to the center of the current scaled content view
        let currentScale = zoomScales[focusedPageIndex]
        let scaledContentViewSize = focusedContentSize(scale: currentScale)
        let scaledContentViewCenter = CGPoint(x: scaledContentViewSize.width / 2.0, y: scaledContentViewSize.height / 2.0)
        let anchorDifferenceFromCenter = anchorLocationInScaledContentView - scaledContentViewCenter // this is the distance from the anchor to the center in the previous scale, before any new zoom happened
        let additionallyScaledDifferenceFromCenter = anchorDifferenceFromCenter * additionalScale // zooming expanded (or contracted) this distance
        let newCenter = anchorLocationInScaledContentView - additionallyScaledDifferenceFromCenter  // add that scaled distance to the anchor location
        let offsetCausedByAdditionalScale = newCenter - scaledContentViewCenter // how much did the center shift from itself due to the scale?
        let descaledOffsetCausedByAdditionalScale = CGPoint(x: offsetCausedByAdditionalScale.dx / (currentScale * additionalScale), y: offsetCausedByAdditionalScale.dy / (currentScale * additionalScale))
        let currentOffset = internalOffsets[focusedPageIndex]
        let combinedOffset = CGSize(width: currentOffset.width + descaledOffsetCausedByAdditionalScale.x, height: currentOffset.height + descaledOffsetCausedByAdditionalScale.y)
        return combinedOffset
    }
    
    func scaledGestureViewSize(_ scale: CGFloat) -> CGSize {
        CGSize(width: pagingPageSize.width * scale, height: pagingPageSize.height * scale)
    }
    
    /// The gesture view and content view are in a ZStack with center alignment.
    /// At rest, the anchor of the content view's scale is also center-anchored, and the gesture view and content view have the same scale applied to them.
    func locationInScaledContentView(ofGestureAnchorPoint gestureAnchor: UnitPoint) -> CGPoint {
        let currentScale = zoomScales[focusedPageIndex]
        let gestureViewSize = scaledGestureViewSize(currentScale)
        let anchorLocationInGestureView = CGPoint(x: gestureViewSize.width * gestureAnchor.x, y: gestureViewSize.height * gestureAnchor.y)
        let gestureViewCenter = CGPoint(x: gestureViewSize.width / 2.0, y: gestureViewSize.height / 2.0)
        let gestureViewDiffAnchorToCenter = anchorLocationInGestureView - gestureViewCenter
        let contentViewSize = focusedContentSize(scale: currentScale)
        let contentViewCenter = CGPoint(x: contentViewSize.width / 2.0, y: contentViewSize.height / 2.0)
        let currentOffset = internalOffsets[focusedPageIndex] // not scaled
        let actualAnchorOffset = CGSize(width: gestureViewDiffAnchorToCenter.dx - currentOffset.width, height: gestureViewDiffAnchorToCenter.dy - currentOffset.height)
        let anchorLocationInScaledContentView = CGPoint(x: contentViewCenter.x + actualAnchorOffset.width, y: contentViewCenter.y + actualAnchorOffset.height)
        return anchorLocationInScaledContentView
    }

    func focusedPageContentAnchorPoint(forGestureViewAnchorPoint gestureAnchor: UnitPoint) -> UnitPoint {
        let anchorLocationInScaledContentView = locationInScaledContentView(ofGestureAnchorPoint: gestureAnchor)
        let scaledContentViewSize = focusedContentSize(scale: zoomScales[focusedPageIndex])
        let anchor = UnitPoint(x: anchorLocationInScaledContentView.x / scaledContentViewSize.width, y: anchorLocationInScaledContentView.y / scaledContentViewSize.height)
        return anchor
    }
    
    func focusedContentSize(scale: CGFloat) -> CGSize {
        let unzoomedSize = contentsFittingSizes[focusedPageIndex]
        let contentsSize = CGSize(width: unzoomedSize.width * scale, height: unzoomedSize.height * scale)
        return contentsSize
    }

    func absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: CGSize, currentPagingOffset: CGSize, gestureIsEnded: Bool) -> CGSize {
        let currentScale = zoomScales[focusedPageIndex]
        let scaledLiveOffset = CGSize(width: liveOffset.width / currentScale, height: liveOffset.height / currentScale)
        let proposedOffset = scaledLiveOffset + internalOffsets[focusedPageIndex]
        let clamped = clampOffset(focusedPageIndex, proposedOffset: proposedOffset, scale: currentScale)
        let excess = proposedOffset - clamped
        
        if excessScrollDirection == nil {
            excessScrollDirection = abs(liveOffset.width / liveOffset.height) > 0.8 ? .horizontal : .vertical
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
            internalOffsets[focusedPageIndex] = clamped
            switch excessScrollDirection {
            case .horizontal:
                let (newFocusedPage, newPagedOffset) = restingPagedOffset(unidirectionalExcessOffset + currentPagingOffset)
                resetLiveTransforms()
                focus(page: newFocusedPage)
                return newPagedOffset
            case .vertical:
                resetLiveTransforms()
                return unidirectionalExcessOffset
            case nil:
                assertionFailure("excessScrollDirection should be known as soon as gesture begins")
                return .zero
            }
        } else {
            focusedPageLiveOffset = clamped - internalOffsets[focusedPageIndex]
            return unidirectionalExcessOffset
        }
    }
    
    private func restingPagedOffset(_ rawOffset: CGSize) -> (Int, CGSize) {
        // find the closest boundary. note that acceptable resting offsets are always <= 0.
        let widthsOffsetNoFurtherThanFinalImage = max(-(CGFloat(pageCount - 1)), (rawOffset.width / pagingPageSize.width).rounded(.toNearestOrEven))
        let widthsOffset = min(widthsOffsetNoFurtherThanFinalImage, 0)
        return (Int(-widthsOffset), CGSize(width: pagingPageSize.width * widthsOffset, height: 0))
    }
    
    func clampOffset(_ index: Int, proposedOffset: CGSize, scale: CGFloat) -> CGSize {
        let baseSize = contentsFittingSizes[index]
        let scaledSize = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
        let contentPageSize = contentPageSizes[index]
        
        let maxX: CGFloat
        let maxY: CGFloat
        let minX: CGFloat
        let minY: CGFloat
        if scaledSize.width <= contentPageSize.width {
            // scaled width is smaller than or equal to page width; do not allow any offset
            maxX = 0
            minX = 0
        } else {
            // scaled width is larger than page width; allow scrolling side to side enough to show the hidden content
            maxX = (scaledSize.width - contentPageSize.width) * 0.5 / scale
            minX = (contentPageSize.width - scaledSize.width) * 0.5 / scale
        }
        if scaledSize.height <= contentPageSize.height {
            // scaled height is smaller than or equal to page height; do not allow any offset
            maxY = 0
            minY = 0
        } else {
            // scaled height is larger than page height; allow scrolling up and down enough to show the hidden content
            maxY = (scaledSize.height - contentPageSize.height) * 0.5 / scale
            minY = (contentPageSize.height - scaledSize.height) * 0.5 / scale
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

extension EnvironmentValues {
    @Entry var pageSize: CGSize = .zero
}

struct PageableZoomableView<Content: View, Controls: View>: View {
    @Environment(PageableZoomableViewModel.self) var pageableZoomableViewModel
    @GestureState private var liveScale: CGFloat = 1
    @GestureState private var liveOffset: CGSize = .zero
    @State private var lastLiveOffset: CGSize = .zero  // this allows us to smoothly animate page changes when the drag gesture ends
    @State private var offset: CGSize = .zero
    
    private let dismissThreshold: CGFloat = 90
    
    let contentView: Content
    let controlsView: Controls
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder controls: () -> Controls) {
        contentView = content()
        controlsView = controls()
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                contentView
                    .environment(\.pageSize, geo.size)
                    .offset(offset + (liveOffset == .zero ? lastLiveOffset : liveOffset))
                
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(pageableZoomableViewModel.restingPageContentsScale(pageableZoomableViewModel.focusedPageIndex), anchor: .center) // applying the same scale to this view as to the content view makes the zooming logic easier
                        .gesture(zoomAndPan) // putting the gesture on a stationary view keeps the motion smooth
                    
                    controlsView // in order to receive touch events, the controls have to be above the clear overlay that holds the zoomAndPan gesture
                }
            }
            .onAppear() {
                offset = pageableZoomableViewModel.updatePagingPageSizeAndReturnNewFocusedPageOffset(geo.size)
            }
            .onChange(of: geo.size) { _, newValue in
                offset = pageableZoomableViewModel.updatePagingPageSizeAndReturnNewFocusedPageOffset(newValue)
            }
        }
        .ignoresSafeArea()
    }
    
    var zoomAndPan: some Gesture {
        SimultaneousGesture(
            MagnifyGesture()
                .updating($liveScale) { value, state, _ in
                    state = value.magnification
                    pageableZoomableViewModel.absorbLiveUpdateZoomScaleIntoFocusedPage(liveScale: value.magnification, gestureAnchor: value.startAnchor, currentOffset: offset, gestureIsEnded: false)
                }
                .onEnded { value in
                    pageableZoomableViewModel.absorbLiveUpdateZoomScaleIntoFocusedPage(liveScale: value.magnification, gestureAnchor: value.startAnchor, currentOffset: offset, gestureIsEnded: true)
                },
            
            DragGesture()
                .updating($liveOffset) { value, state, _ in
                    let excessOffset = pageableZoomableViewModel.absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: value.translation, currentPagingOffset: offset, gestureIsEnded: false)
                    state = excessOffset
                    lastLiveOffset = excessOffset
                }
                .onEnded { value in
                    offset = offset + lastLiveOffset
                    lastLiveOffset = .zero
                    withAnimation {
                        let excessOffset = pageableZoomableViewModel.absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: value.translation, currentPagingOffset: offset, gestureIsEnded: true)
                        if abs(excessOffset.height) > dismissThreshold {
                            pageableZoomableViewModel.dismiss()
                        } else {
                            offset = CGSize(width: excessOffset.width, height: 0)
                        }
                    }
                }
        )
    }
}

struct ZoomableContentView<Content: View>: View {
    @Environment(PageableZoomableViewModel.self) var pageableZoomableViewModel
    @Environment(\.pageSize) private var pageSize
    let contentFullSize: CGSize
    let index: Int
    let contentView: Content
    
    public init(contentFullSize: CGSize, index: Int, @ViewBuilder content: () -> Content) {
        self.contentFullSize = contentFullSize
        self.index = index
        self.contentView = content()
    }
    
    @State private var fittingSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.dimmingBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            GeometryReader { geo in
                ZStack(alignment: .center) {
                    Color.clear
                        .frame(width: geo.size.width, height: geo.size.height)
                    
                    contentView
                        .frame(width: fittingSize.width, height: fittingSize.height)
                        .offset(pageableZoomableViewModel.liveUpdatePageContentsOffset(index))
                        .scaleEffect(pageableZoomableViewModel.restingPageContentsScale(index))
                        .scaleEffect(pageableZoomableViewModel.liveUpdatePageContentsAdditionalScale(index),
                                     anchor: pageableZoomableViewModel.liveUpdateScaleAnchor(index)
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
        .frame(width: pageSize.width, height: pageSize.height)
        .clipped()
    }
    
    func updateGeometry(fromSize size: CGSize) {
        pageableZoomableViewModel.updateContentPageSize(index, newSize: size)
        fittingSize = calculateFittingSize(fromContainerSize: size)
        pageableZoomableViewModel.updateContentsFittingSize(index, newSize: fittingSize)
    }
    
    func calculateFittingSize(fromContainerSize containerSize: CGSize) -> CGSize {
        let contentAspect = contentFullSize.aspectRatio
        if contentAspect < containerSize.aspectRatio {
            // image is taller.  make the height fit.
            let scale = containerSize.height / contentFullSize.height
            return CGSize(width: contentFullSize.width * scale, height: containerSize.height)
        } else {
            // image is squatter.  make the width fit.
            let scale = containerSize.width / contentFullSize.width
            return CGSize(width: containerSize.width, height: contentFullSize.height * scale)
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
