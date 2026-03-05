// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import PhotosUI
import SwiftUI

struct PhotoCropperView: View {
    public let originalImage: UIImage
    public let completion: (UIImage?)->()
    
    @State var croppedImage: Image?
    
    public init(originalImage: UIImage, completion: @escaping (UIImage?) -> Void) {
        self.originalImage = originalImage
        self.completion = completion
    }
    
    private let cropSize = CGSize(width: 250, height: 250)
    
    private let maxScale: CGFloat = 4
    private var minScale: CGFloat = 1
    @State private var geoSize: CGSize = .zero
    
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    
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
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
                ZStack {
                    let baseSize = baseSize()
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: baseSize.width, height: baseSize.height)
                        .scaleEffect(liveUpdateScale, anchor: .center)
                        .offset(
                            liveUpdateOffset
                        )
                    mask()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                
                HStack {
                    Button() {
                        completion(nil)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .padding()
                            .clipShape(.circle)
                    }
                    .glassEffectIfAvailable(.regular(interactive: true), in: .circle)
                    
                    Spacer()
                    
                    Button() {
#if DEBUG && false
                        if let cropped = getCroppedImage() {
                            croppedImage = Image(uiImage: cropped)
                        }
#else
                        completion(getCroppedImage())
#endif
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title)
                            .padding()
                            .clipShape(.circle)
                    }
                    .glassEffectIfAvailable(.regular(interactive: true), in: .circle)
                }
                .padding()
            }
            .gesture(zoomAndPan)
            .preference(key: SizePreferenceKey.self,
                        value: geo.size)
            .onPreferenceChange(SizePreferenceKey.self) { newValue in
                geoSize = newValue
                offset = clampOffset(offset)
                scale = clampZoom(scale)
            }
        }
    }
    
    func clampOffset(_ proposedOffset: CGSize) -> CGSize {
        let baseSize = baseSize()
        let scaledSize = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
        let restingOffsetFromCropArea = CGSize(width: (scaledSize.width - cropSize.width) / 2.0, height: (scaledSize.height - cropSize.height) / 2.0)
        let maxOffset = CGSize(width: restingOffsetFromCropArea.width, height: restingOffsetFromCropArea.height)
        let minOffset = CGSize(width: -(scaledSize.width - restingOffsetFromCropArea.width - cropSize.width), height: -(scaledSize.height - restingOffsetFromCropArea.height - cropSize.height))
        let clamped = CGSize(width: max(minOffset.width, min(proposedOffset.width, maxOffset.width)), height: max(minOffset.height, min(proposedOffset.height, maxOffset.height)))
        return clamped
    }
    
    func clampZoom(_ proposedScale: CGFloat) -> CGFloat {
        let clamped = min(maxScale, max(proposedScale, minScale))
        return clamped
    }
    
    @ViewBuilder func mask() -> some View {
        ZStack {
            ZStack {
                Color.dimmingBackground
                    .ignoresSafeArea()
                RoundedRectangle(cornerRadius: cropSize.width * 0.2)
                    .frame(width: cropSize.width, height: cropSize.height)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            
            RoundedRectangle(cornerRadius: cropSize.width * 0.2)
                .stroke(.white, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [8, 12]))
                .frame(width: cropSize.width, height: cropSize.height)
        }
    }
    
    func baseSize() -> CGSize {
        let aspect = originalImage.size.aspectRatio
        if aspect < cropSize.aspectRatio {
            // image is taller.  make the width fit.
            return CGSize(width: cropSize.width, height: cropSize.width / aspect)
        } else {
            // image is squatter.  make the height fit.
            return CGSize(width: cropSize.height * aspect, height: cropSize.height)
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
                }
                .onEnded { value in
                    let proposedOffest = CGSize(width:  offset.width + value.translation.width, height: offset.height + value.translation.height)
                    offset = clampOffset(proposedOffest)
                }
        )
    }
    
    func getCroppedImage() -> UIImage? {
        let baseSize = baseSize()
        let scaledSizeFromBase = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
        let restingOffsetFromCropArea = CGSize(width: (scaledSizeFromBase.width - cropSize.width) / 2.0, height: (scaledSizeFromBase.height - cropSize.height) / 2.0)
        let uiCroppingRect = CGRect(origin: CGPoint(x: restingOffsetFromCropArea.width - offset.width, y: restingOffsetFromCropArea.height - offset.height), size: cropSize)
        
        let scaleFromBaseSize = baseSize.width / originalImage.size.width
        let totalScale = 1 / (scale * scaleFromBaseSize)
        let imageCroppingRect = uiCroppingRect.applying(CGAffineTransform(scaleX: totalScale, y: totalScale))
        let result = originalImage.cropped(to: imageCroppingRect)
        return result
    }
}

extension UIImage {
    func cropped(to rect: CGRect) -> UIImage? {
        let normalized = normalizedOrientation()
        guard let cgImage = normalized.cgImage else { return nil }
        guard let cropped = cgImage.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped)
    }

    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized!
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
