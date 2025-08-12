// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct ZoomableBlurhashImageView: View {
    let image: MastodonImageAttachment
    @Environment(ImageGalleryViewModel.self) private var viewModel 
    let frameSize: CGSize
   
    var body: some View {
        let originalSize = image.imageDetails.originalSize ?? frameSize
        let aspectRatio = CGFloat(originalSize.height) > 0 ? CGFloat(originalSize.width) / CGFloat(max(0.1, originalSize.height)) : 1
        let baseSize = sizeThatFits(aspectRatio: aspectRatio, in: frameSize)
        GeometryReader { geo in
            ZoomableScrollView {
                BlurhashImageView(url: image.basicData.fullsizeUrl, imageDetails: image.imageDetails, blurhash: viewModel.blurhashes[image.id])
                    .environment(ContentConcealViewModel.alwaysShow)
                    .frame(width: baseSize.width, height: baseSize.height)
            }
        }
    }
    
    private func sizeThatFits(aspectRatio: CGFloat, in container: CGSize) -> CGSize {
        // Fit the image proportionally within the container
        let containerAR = container.width / container.height
        
        if aspectRatio > containerAR {
            // image is wider relative to container — constrain width
            let width = container.width
            let height = width / aspectRatio
            return CGSize(width: width, height: height)
        } else {
            // image is taller — constrain height
            let height = container.height
            let width = height * aspectRatio
            return CGSize(width: width, height: height)
        }
    }
}
