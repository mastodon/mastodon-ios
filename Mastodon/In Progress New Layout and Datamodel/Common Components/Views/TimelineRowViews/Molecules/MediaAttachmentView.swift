// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import AVKit
import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonLocalization
import Combine
import MastodonAsset
import SDWebImageSwiftUI

let buttonBackgroundColor = Color.black.opacity(0.6)
let maxHeightForHiddenMedia: CGFloat = 100

class GenericMastodonAttachment: Identifiable {
    let id: Mastodon.Entity.Attachment.ID
    let basicData: MastodonAttachmentBasicData
    let _legacyEntity: Mastodon.Entity.Attachment
    
    init(entity: Mastodon.Entity.Attachment) {
        id = entity.id
        basicData = MastodonAttachmentBasicData(entity)
        _legacyEntity = entity
    }
}

class MastodonImageAttachment: GenericMastodonAttachment {
    let imageDetails: ImageAttachmentDetails
    
    init?(_ entity: Mastodon.Entity.Attachment) {
        guard let meta = entity.meta else { return nil }
        imageDetails = ImageAttachmentDetails(meta)
        super.init(entity: entity)
    }
}

class MastodonPlayableAttachment: GenericMastodonAttachment {
    let imageDetails: ImageAttachmentDetails?
    let duration: Double?
    
    init?(_ entity: Mastodon.Entity.Attachment) {
        guard let meta = entity.meta else { return nil }
        imageDetails = ImageAttachmentDetails(meta)
        duration = meta.duration
        super.init(entity: entity)
    }
    
    var url: URL? {
        return basicData.fullsizeUrl
    }
    
    var size: CGSize? {
        return imageDetails?.originalSize
    }
    
    var blurhash: String? {
        return basicData.blurhash
    }
}

struct MastodonAttachmentBasicData {
    let id: Mastodon.Entity.Attachment.ID
    let fullsizeUrl: URL?
    let previewUrl: URL?
    let remoteUrl: URL?  // null if the attachment is local
    let altText: String?
    let blurhash: String?
    
    init(_ entity: Mastodon.Entity.Attachment) {
        id = entity.id
        func url(nullableString: String?) -> URL? {
            guard let string = nullableString else { return nil }
            return URL(string: string)
        }
        fullsizeUrl = url(nullableString: entity.url)
        previewUrl = url(nullableString:entity.previewURL)
        remoteUrl = url(nullableString:entity.remoteURL)
        altText = entity.description
        blurhash = entity.blurhash
    }
}

extension CGSize {
    static func fromFormat(_ format: Mastodon.Entity.Attachment.Meta.Format) -> CGSize? {
        guard let width = format.width, let height = format.height else { return nil }
        return CGSize(width: Double(width), height: Double(height))
    }
    
    var aspectRatio: CGFloat {
        guard width > 0, height > 0 else { return 1 }
        return width / height
    }
}

struct ImageAttachmentDetails {
    
    let originalSize: CGSize?
    let smallSize: CGSize?
    let focusPercentOffCenterX: CGFloat?  // value between -1(left) and 1(right)
    let focusPercentOffCenterY: CGFloat?  // value between -1(bottom) and 1(top)
    
    init(_ meta: Mastodon.Entity.Attachment.Meta) {
        if let originalSizeFormat = meta.original {
            originalSize = CGSize.fromFormat(originalSizeFormat)
        } else {
            originalSize = nil
        }
        
        if let smallSizeFormat = meta.small {
            smallSize = CGSize.fromFormat(smallSizeFormat)
        } else {
            smallSize = nil
        }
        
        if let focus = meta.focus {
            focusPercentOffCenterX = focus.x
            focusPercentOffCenterY = focus.y
        } else {
            focusPercentOffCenterX = nil
            focusPercentOffCenterY = nil
        }
    }
}

enum MediaAttachment {
    case images([MastodonImageAttachment], altTextTranslations: [String : String]?)
    case gifv(MastodonPlayableAttachment, altTextTranslation: String?)
    case video(MastodonPlayableAttachment, altTextTranslation: String?)
    case audio(MastodonPlayableAttachment, altTextTranslation: String?)
    case openInBrowser(URL)
    case notYetImplemented(String)
    case emptyAttachment
    
    init(_ media: [Mastodon.Entity.Attachment], altTextTranslations: [String : String]?) {
        switch media.first?.type {
        case .none:
            self = .emptyAttachment
        case .image:
            let images = media.map { attachment in
                MastodonImageAttachment(attachment)
            }.compactMap { $0 }
            if images.isNotEmpty {
                self = .images(images, altTextTranslations: altTextTranslations)
            } else {
                self = .emptyAttachment
            }
        case .gifv:
            if let entity = media.first, let attachment = MastodonPlayableAttachment(entity) {
                self = .gifv(attachment, altTextTranslation: altTextTranslations?.values.first)
            } else {
                self = .emptyAttachment
            }
        case .video:
            if let entity = media.first, let attachment = MastodonPlayableAttachment(entity) {
                self = .video(attachment, altTextTranslation: altTextTranslations?.values.first)
            } else {
                self = .emptyAttachment
            }
        case .audio:
            if let entity = media.first, let attachment = MastodonPlayableAttachment(entity) {
                self = .audio(attachment, altTextTranslation: altTextTranslations?.values.first)
            } else {
                self = .emptyAttachment
            }
        case .unknown:
            if let entity = media.first, let urlString = entity.url ?? entity.remoteURL, let url = URL(string: urlString) {
                self = .openInBrowser(url)
            } else {
                self = .emptyAttachment
            }
        case ._other(let string):
            self = .notYetImplemented(string)
        }
    }
}

extension MediaAttachment {
    @MainActor
    @ViewBuilder func view(actionHandler: MastodonPostMenuActionHandler) -> some View {
        switch self {
        case .emptyAttachment:
            Image(systemName: "questionmark.square.dashed")
        case .images(let attachments, let altTextTranslations):
            ConcealableMediaAttachmentView() {
                ImageGridView(mediaPreviewableViewController: actionHandler.mediaPreviewableViewController)
                    .environment(ImageGalleryViewModel(imageAttachments: attachments, altTextTranslations: altTextTranslations, actionHandler: actionHandler))
            }
        case .audio, .gifv, .video:
            ConcealableMediaAttachmentView() {
                PlayerView(media: self, actionHandler: actionHandler)
            }
        case .openInBrowser(let url):
            Button {
                actionHandler.presentScene(.safari(url: url), fromPost: nil, transition: .show)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(L10n.Common.Controls.Status.Media.previewNotAvailable)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(L10n.Common.Controls.Status.Media.tapToOpenInBrowser)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .background {
                    MastodonSecondaryBackground(fillInDarkModeOnly: false)
                }
            }
            .buttonStyle(.borderless)
        case .notYetImplemented(let string):
            Text("Needs Implementation (\(string))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct ConcealableMediaAttachmentView<Content: View>: View {
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    let contentViewBuilder: () -> Content

    init(@ViewBuilder content: @escaping() -> Content) {
        self.contentViewBuilder = content
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) { // places the Hide/Show button, if there is one
            
            contentViewBuilder()
            
            // Hide/Show button
            switch contentConcealViewModel.currentMode {
            case .neverConceal, .concealAll:
                EmptyView()
            case .concealMediaOnly(let showAnyway):
                Button {
                    if showAnyway {
                        contentConcealViewModel.hide()
                    } else {
                        contentConcealViewModel.showMore()
                    }
                } label: {
                    Text(showAnyway ? L10n.Common.Controls.Status.Actions.hide : L10n.Common.Controls.Status.Actions.show)
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: ButtonPadding.vertical, leading: ButtonPadding.capsuleHorizontal, bottom: ButtonPadding.vertical, trailing: ButtonPadding.capsuleHorizontal))
                        .background() {
                            Capsule()
                                .fill(buttonBackgroundColor)
                        }
                }
                .fixedSize()
                .buttonStyle(.borderless)
                .padding(standardPadding)
            }
        }
    }
    
}

struct ImageGridView: View {
    @Environment(ImageGalleryViewModel.self) private var viewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    let mediaPreviewableViewController: MediaPreviewableViewController?
    @State var waitingToShowFullSize: String? = nil
    
    var body: some View {
        // The images
        let useRestrictedHeight = viewModel.useRestrictedHeight(inConcealMode: contentConcealViewModel.currentMode)
        ProportionalImageGridLayout(spacing: 1, aspectRatios: viewModel.imageAttachments.compactMap(\.imageDetails.originalSize?.aspectRatio), canUseTwoRows: !useRestrictedHeight) {
            ForEach(viewModel.imageAttachments) { img in
                ZStack(alignment: .bottomLeading) { // places the ALT text button
                    BlurhashImageView(url: img.basicData.fullsizeUrl, imageDetails: img.imageDetails, blurhash: viewModel.blurhashes[img.id])
                        .clipped()
                        .accessibilityLabel(viewModel.altTextTranslations?[img.id] ?? img.basicData.altText ?? "")
                        .onTapGesture {
                            waitingToShowFullSize = img.id
                        }
                        .background {
                            if waitingToShowFullSize != nil {
                                FrameReader() { updatedFrame in
                                    viewModel.updateFrame(updatedFrame, forID: img.basicData.id)
                                    if waitingToShowFullSize == img.id {
                                        waitingToShowFullSize = nil
                                        Task { @MainActor in
                                            showImageGallery(focusing: img.id)
                                        }
                                    }
                                }
                            }
                        }
                    
                    if let altText = img.basicData.altText, altText.isNotEmpty {
                        Button {
                            if let translation = viewModel.altTextTranslations?[img.id] {
                                viewModel.actionHandler.showOverlay(.altText(translation))
                            } else {
                                viewModel.actionHandler.showOverlay(.altText(altText))
                            }
                        } label: {
                            Text("ALT")
                                .foregroundStyle(.white)
                                .padding(EdgeInsets(top: ButtonPadding.vertical, leading: ButtonPadding.horizontal, bottom: ButtonPadding.vertical, trailing: ButtonPadding.horizontal))
                                .background() {
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .fill(buttonBackgroundColor)
                                }
                        }
                        .fixedSize()
                        .padding(standardPadding)
                        .buttonStyle(.borderless)
                        .accessibilityHidden(true)
                    }
                }
                .frame(maxHeight: useRestrictedHeight ? maxHeightForHiddenMedia : nil)
            }
        }
        .frame(maxHeight: useRestrictedHeight ? maxHeightForHiddenMedia : nil)
        .cornerRadius(CornerRadius.standard)
        .animation(.easeInOut, value: contentConcealViewModel.currentMode.isShowingMedia)
    }
    
    func showImageGallery(focusing: Mastodon.Entity.Attachment.ID) {
        guard let presentingViewController = viewModel.actionHandler.mediaPreviewableViewController else { return }
        
        let focusedIndex = viewModel.imageAttachments.firstIndex { $0.id == focusing }
        
        let altTextTranslations = viewModel.altTextTranslations
        let altTexts = viewModel.imageAttachments.map { altTextTranslations?[$0.id] ?? $0.basicData.altText }
       
        let previewItem: MediaPreviewViewModel.PreviewItem = .attachments(viewModel.imageAttachments.map{ $0._legacyEntity }, initialIndex: focusedIndex, altTexts: altTexts)
        let mediaPreviewTransitionItem: MediaPreviewTransitionItem = {
            @MainActor func clippingFrame(forID id: Mastodon.Entity.Attachment.ID) -> CGRect { viewModel.frame(forID: id) ?? CGRect(x: 50, y: 50, width: 50, height: 50)
            }
            let clippingFrames = viewModel.imageAttachments.map { clippingFrame(forID: $0.basicData.id) }
            let item = MediaPreviewTransitionItem(source: .swiftUI(sourceFramesInScreenCoordinates: clippingFrames), previewableViewController: presentingViewController)
            
            item.initialClippingFrame = {
                // this is the current frame of the image view
                let initialFrame = clippingFrame(forID: focusing)
                assert(initialFrame != .zero)
                return initialFrame
            }()
            item.initialimageFrame = {
                // this is the current frame of the image in the view, accounting for focus point if cropping
                let initialFrame = viewModel.frame(forID: focusing) ?? CGRect(x: 50, y: 50, width: 50, height: 50)
                assert(initialFrame != .zero)
                return initialFrame
            }()
            
            item.image = viewModel.blurhashes[focusing]
            
            item.aspectRatio = {
                guard let focusedIndex else { return nil }
                return viewModel.imageAttachments[focusedIndex].imageDetails.originalSize
            }()
            
            return item
        }()
        
        let mediaPreviewViewModel = MediaPreviewViewModel(
            item: previewItem,
            transitionItem: mediaPreviewTransitionItem)
        viewModel.actionHandler.presentScene(.mediaPreview(viewModel: mediaPreviewViewModel),
                                             fromPost: nil,
                                             transition: .custom(transitioningDelegate: presentingViewController.mediaPreviewTransitionController)
        )
    }
}

struct BlurhashImageView: View {
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    let url: URL?
    let imageDetails: ImageAttachmentDetails
    let blurhash: UIImage?
    
    var body: some View {
        ZStack {
            if let blurhash {
                Image(uiImage: blurhash)
                    .resizable()
                    .scaledToFit()
            }
            
            if let url {
                WebImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        EmptyView() // show blurhash behind
                    case .success(let image):
                        switch contentConcealViewModel.currentMode {
                        case .neverConceal, .concealMediaOnly(showAnyway: true), .concealAll(_, showAnyway: true):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            EmptyView()
                        }
                    case .failure:
                        Image(systemName: "photo.badge.exclamationmark")
                            .tint(.secondary)
                            .opacity(0.5)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

@MainActor
@Observable
class ImageGalleryViewModel {
    let imageAttachments: [MastodonImageAttachment]
    private var frames = [Mastodon.Entity.Attachment.ID : CGRect]()
    let altTextTranslations: [String : String]?
    var blurhashes = [ Mastodon.Entity.Attachment.ID : UIImage ]()
    let actionHandler: MastodonPostMenuActionHandler
    
    init(imageAttachments: [MastodonImageAttachment], altTextTranslations: [String: String]?, actionHandler: MastodonPostMenuActionHandler) {
        self.imageAttachments = imageAttachments
        self.altTextTranslations = altTextTranslations
        self.actionHandler = actionHandler
        loadBlurhashes()
    }
    
    private func loadBlurhashes() {
        Task {
            for imageData in imageAttachments {
                if let blurhash = imageData.basicData.blurhash, let url = imageData.basicData.fullsizeUrl, let size = imageData.imageDetails.originalSize {
                    blurhashes[imageData.id] = try? await BlurhashImageCacheService.shared.image(
                        blurhash: blurhash,
                        size: size,
                        url: url.absoluteString
                    ).singleOutput()
                }
            }
        }
    }
    
    func useRestrictedHeight(inConcealMode currentMode: ContentConcealViewModel.ContentDisplayMode) -> Bool {
        switch currentMode {
        case .neverConceal:
            return false
        case .concealAll(_, let showAnyway), .concealMediaOnly(let showAnyway):
            return !showAnyway
        }
    }
    
    func frame(forID id: Mastodon.Entity.Attachment.ID) -> CGRect? {
        return frames[id]
    }
    
    func updateFrame(_ newFrame: CGRect, forID id: Mastodon.Entity.Attachment.ID) {
        frames[id] = newFrame
    }
}

struct PlayerView: View {
    let media: MediaAttachment
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    @StateObject var playerObserver = VideoPlayerObserver()
    let player: AVPlayer?
    let actionHandler: MastodonPostMenuActionHandler
    @State var waitingToShowFullSize = false
    
    init(media: MediaAttachment, actionHandler: MastodonPostMenuActionHandler) {
        self.media = media
        self.actionHandler = actionHandler
        
        if let attachmentInfo = media.attachmentInfo, let url = attachmentInfo.url {
            self.player = AVPlayer(url: url)
        } else {
            self.player = nil
        }
    }
    
    var body: some View {
        ZStack {
            if let blurImage = playerObserver.blurImage {
                Image(uiImage: blurImage)
                    .resizable()
                    .scaledToFill()
            }
            
            VideoPlayer(player: playerObserver.player)
                .background {
                    if waitingToShowFullSize {
                        FrameReader() { frame in
                            playerObserver.mostRecentFrameInScreenCoordinates = frame
                            if waitingToShowFullSize {
                                waitingToShowFullSize = false
                                Task { @MainActor in
                                    showFullSize()
                                }
                            }
                        }
                    }
                }
        }
        .overlay {
            ZStack {
                Button {
                    waitingToShowFullSize = true
                } label: {
                    Rectangle().fill(.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.borderless)
                
                if shouldShowPlayButton && !playerObserver.isPlaying {
                    Button {
                        playerObserver.player?.play()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .padding(EdgeInsets(top: standardPadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                            .background() {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .onAppear() {
            if let player, player != playerObserver.player {
                playerObserver.startObserving(player: player, shouldLoop: shouldLoop)
            }
            if let attachmentInfo = media.attachmentInfo, let url = attachmentInfo.url, let blurhash = attachmentInfo.blurhash, let size = attachmentInfo.size {
                Task {
                    playerObserver.blurImage = try? await BlurhashImageCacheService.shared.image(blurhash: blurhash, size: size, url: url.absoluteString).singleOutput()
                }
            }
        }
        .onDisappear() {
            playerObserver.player?.pause()
        }
    }
    
    var shouldLoop: Bool {
        switch media {
        case .gifv:
            return true
        default:
            return false
        }
    }
    
    var shouldShowPlayButton: Bool {
        switch media {
        case .gifv, .video, .audio:
            return true
        default:
            return false
        }
    }
    
    func showFullSize() {
        player?.pause()
        guard let _legacyEntity = media.attachmentInfo?._legacyEntity, let previewableViewController = actionHandler.mediaPreviewableViewController else { return }
        let previewItem: MediaPreviewViewModel.PreviewItem = .attachments([_legacyEntity], initialIndex: 0, altTexts: [media.attachmentInfo?.basicData.altText ?? ""])
        let mediaPreviewTransitionItem: MediaPreviewTransitionItem = {
            let item = MediaPreviewTransitionItem(source: .swiftUI(sourceFramesInScreenCoordinates: [playerObserver.mostRecentFrameInScreenCoordinates]), previewableViewController: previewableViewController)
            
            item.initialClippingFrame = {
                // this is the current frame of the player
                let initialFrame = playerObserver.mostRecentFrameInScreenCoordinates
                assert(initialFrame != .zero)
                return initialFrame
            }()
            item.initialimageFrame = CGRect(x: 0, y: 0, width: item.initialClippingFrame?.width ?? 1, height: item.initialimageFrame?.height ?? 1)
            
            item.image = playerObserver.blurImage
            
            item.aspectRatio = item.initialClippingFrame?.size
            
            return item
        }()
        
        let mediaPreviewViewModel = MediaPreviewViewModel(
            item: previewItem,
            transitionItem: mediaPreviewTransitionItem)
        actionHandler.presentScene(.mediaPreview(viewModel: mediaPreviewViewModel),
                                   fromPost: nil,
                                   transition: .custom(transitioningDelegate: previewableViewController.mediaPreviewTransitionController)
        )
    }
}

extension MediaAttachment {
    var attachmentInfo: MastodonPlayableAttachment? {
        switch self {
        case .gifv(let info, _), .video(let info, _), .audio(let info, _):
            return info
        case .images, .notYetImplemented, .emptyAttachment:
            return nil
        case .openInBrowser:
            return nil
        }
    }
}

class VideoPlayerObserver: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published private(set) var player: AVPlayer?
    @Published var blurImage: UIImage? = nil
    private var cancellable: AnyCancellable?
    var mostRecentFrameInScreenCoordinates = CGRect(x: 50, y: 50, width: 50, height: 50)
    
    func startObserving(player: AVPlayer, shouldLoop: Bool) {
        self.cancellable?.cancel()
        self.player?.pause()
        self.player = player
        self.cancellable = player.publisher(for: \.rate, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .map { $0 != 0 }
            .assign(to: \.isPlaying, on: self)
        
        if shouldLoop {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.cancellable?.cancel()
        player?.pause()
    }
}
