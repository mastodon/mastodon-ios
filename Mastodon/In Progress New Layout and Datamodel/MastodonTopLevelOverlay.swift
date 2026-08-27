// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import SwiftUI
import MastodonLocalization
import MastodonUI

enum MastodonFadeInOverlay {
    case images(ImageGalleryViewModel, PageableZoomableViewModel)
    case video(MediaAttachment, PageableZoomableViewModel)
    case altText(String)
}

struct MastodonTopLevelOverlay<Content: View> : View {
    let didRequestDismiss: ()->()
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.dimmingBackground
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    didRequestDismiss()
                }
            
            content
            
            Button() {
                didRequestDismiss()
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .padding(standardPadding)
        }
    }
}

struct FullSizeImageGallery: View {
    @Environment(ImageGalleryViewModel.self) private var viewModel
    @Environment(PageableZoomableViewModel.self) private var pageableZoomableModel
    
    @State private var displayAltText: String?
    
    var body: some View {
        PageableZoomableView() {
            PagingImageGalleryContent()
        } controls: {
            let currentAttachment = viewModel.imageAttachments[pageableZoomableModel.focusedPageIndex]
            VStack(alignment: .trailing) {
                if let sharableImage = viewModel.sharableImages[currentAttachment.id] {
                    ShareLink(item: sharableImage, preview: SharePreview(currentAttachment.basicData.shareTitle ?? L10nLookup.CommonControls.genericImageDescription, image: sharableImage))
                        .padding(.vertical, ButtonPadding.vertical)
                        .padding(.horizontal, ButtonPadding.horizontal)
                        .background() {
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(buttonBackgroundColor)
                        }
                        .environment(\.colorScheme, .dark)
                }
                if let currentPageAltText = viewModel.altTextTranslations?[currentAttachment.id] ?? currentAttachment.basicData.altText {
                    AltTextButton(drawBorder: true, altText: currentPageAltText, displayAltText: Binding<String?>(
                        get: { displayAltText },
                        set: { newValue in displayAltText = newValue}
                    ))
                }
                Spacer()
            }
            .padding(.vertical, 80)
            .padding(.horizontal, doublePadding)
            .frame(width: pageableZoomableModel.pagingPageSize.width, height: pageableZoomableModel.pagingPageSize.height, alignment: .topTrailing)
        }
        .overlay {
            AltTextOverlay(altTextBinding: Binding<String?>(
                get: { displayAltText },
                set: { newValue in displayAltText = newValue}
            ))
        }
    }
}

struct FullSizeVideoOverlayView: View {
    let attachment: MediaAttachment
    
    @StateObject private var playerObserver = PlayerObserver()
    
    var body: some View {
        PageableZoomableView() {
            HStack {
                ZoomableContentView(contentFullSize: attachment.attachmentInfo?.imageDetails?.originalSize ?? .zero, index: 0) {
                    VideoPlayerView(playerObserver: playerObserver, media: attachment, originalSize: attachment.attachmentInfo?.imageDetails?.originalSize ?? .zero,
                                    containerOverlayBinding: nil)
                }
            }
        } controls: {
            playerObserver.playButton(playerObserver.playingState)
        }
    }
}

struct PagingImageGalleryContent: View {
    @Environment(\.pageSize) var pageSize
    @Environment(ImageGalleryViewModel.self) var galleryViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(galleryViewModel.imageAttachments, id: \.self.id) { imageInfo in
                let index = galleryViewModel.idToIndex[imageInfo.id] ?? 0
                ZoomableContentView(contentFullSize: galleryViewModel.imageAttachments[index].imageDetails.originalSize ?? .zero,
                                    index: index) {
                    BlurhashImageView(url: imageInfo.basicData.fullsizeUrl, imageDetails: imageInfo.imageDetails, shareTitle: imageInfo.basicData.shareTitle, blurhash: galleryViewModel.blurhashes[imageInfo.basicData.id])
                    { image in
                        galleryViewModel.sharableImages[imageInfo.basicData.id] = image
                    }
                }
            }
        }
    }
}
