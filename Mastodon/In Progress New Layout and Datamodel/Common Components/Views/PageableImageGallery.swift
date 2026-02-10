// Copyright © 2026 Mastodon gGmbH. All rights reserved.
import SwiftUI
import MastodonSDK

@Observable class PageableZoomableViewModel {
    let pageCount: Int
    let dismiss: ()->()
    
    private(set) var focusedPageIndex: Int = 0
    let maxZoom: CGFloat = 4
    let minZoom: CGFloat = 1
    
    private var zoomScales: [CGFloat]
    private var internalOffsets: [CGSize]
    private var focusedPageContentsFittingSizes: [CGSize]
    
    private var focusedPageLiveZoomScale: CGFloat = 1
    private var focusedPageLiveOffset: CGSize = .zero
    
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
            internalOffsets[i] = clampOffset(i, proposedOffset: offset)
        }
    }
    
    private func resetLiveTransforms() {
        focusedPageLiveZoomScale = 1
        focusedPageLiveOffset = .zero
        excessScrollDirection = nil
    }
    
    func liveUpdatePageContentsOffset(_ index: Int) -> CGSize {
        if index == focusedPageIndex {
            return internalOffsets[index] + focusedPageLiveOffset
        } else {
            return internalOffsets[index]
        }
    }
    
    func liveUpdatePageContentsScale(_ index: Int) -> CGFloat {
        if index == focusedPageIndex {
            return zoomScales[index] * focusedPageLiveZoomScale
        } else {
            return zoomScales[index]
        }
    }
    
    func absorbLiveUpdateZoomScaleIntoFocusedPage(liveScale: CGFloat, gestureIsEnded: Bool) {
        let proposedScale = liveScale * zoomScales[focusedPageIndex]
        let clamped = clampZoom(proposedScale)
        focusedPageLiveZoomScale = clamped / zoomScales[focusedPageIndex]
        
        if gestureIsEnded  {
            zoomScales[focusedPageIndex] = clamped
            resetLiveTransforms()
        }
    }
    
    func absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: CGSize, currentOffset: CGSize, gestureIsEnded: Bool) -> CGSize {
        let proposedOffset = liveOffset + internalOffsets[focusedPageIndex]
        let clamped = clampOffset(focusedPageIndex, proposedOffset: proposedOffset)
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
            internalOffsets[focusedPageIndex] = clamped
            switch excessScrollDirection {
            case .horizontal:
                let (newFocusedPage, newPagedOffset) = restingPagedOffset(unidirectionalExcessOffset + currentOffset)
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
    
    func clampOffset(_ index: Int, proposedOffset: CGSize) -> CGSize {
        let baseSize = contentsFittingSizes[index]
        let scaledSize = CGSize(width: baseSize.width * zoomScales[index], height: baseSize.height * zoomScales[index])
        let contentPageSize = contentPageSizes[index]
        
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

extension EnvironmentValues {
    @Entry var pageSize: CGSize = .zero
}

struct PageableZoomableView<Content: View, Controls: View>: View {
    @Environment(PageableZoomableViewModel.self) var pageableZoomableViewModel
    @GestureState private var liveScale: CGFloat = 1
    @GestureState private var liveOffset: CGSize = .zero
    @State private var lastLiveOffset: CGSize = .zero  // this allows us to smoothly animate page changes when the drag gesture ends
    @State private var offset: CGSize = .zero
    
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
                        .scaleEffect(pageableZoomableViewModel.liveUpdatePageContentsScale(pageableZoomableViewModel.focusedPageIndex), anchor: .topLeading)
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
                    lastLiveOffset = excessOffset
                    print("updating drag \(value.translation)")
                }
                .onEnded { value in
                    offset = offset + lastLiveOffset
                    lastLiveOffset = .zero
                    withAnimation {
                        let excessOffset = pageableZoomableViewModel.absorbLiveUpdateOffsetIntoFocusedPageAndReturnExcess(liveOffset: value.translation, currentOffset: offset, gestureIsEnded: true)
                        if abs(excessOffset.height) > (pageableZoomableViewModel.pagingPageSize.height / 2.0) {
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
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                    Color.clear
                        .frame(width: geo.size.width, height: geo.size.height)
                    
                    contentView
                        .frame(width: fittingSize.width, height: fittingSize.height)
                        .scaleEffect(pageableZoomableViewModel.liveUpdatePageContentsScale(index),
                                     anchor: .topLeading
                        )
                        .offset(pageableZoomableViewModel.liveUpdatePageContentsOffset(index))
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
            return CGSize(width: containerSize.width * contentAspect, height: containerSize.height)
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
