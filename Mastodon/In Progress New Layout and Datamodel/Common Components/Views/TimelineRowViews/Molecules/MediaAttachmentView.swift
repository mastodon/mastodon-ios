// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import AVKit
import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonUI
import MastodonLocalization
import Combine
import MastodonAsset
import SDWebImageSwiftUI

let buttonBackgroundColor = Color.dimmingBackground
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
    @ViewBuilder func view(actionHandler: MastodonPostMenuActionHandler?) -> some View {
        switch self {
        case .emptyAttachment:
            Image(systemName: "questionmark.square.dashed")
        case .images(let attachments, let altTextTranslations):
            ConcealableMediaAttachmentView() {
                ImageGridView(actionHandler: actionHandler)
                    .environment(ImageGalleryViewModel(imageAttachments: attachments, altTextTranslations: altTextTranslations, actionHandler: actionHandler))
            }
        case .audio:
            AudioPlayerView(media: self)
        case .gifv, .video:
            ConcealableMediaAttachmentView() {
                VideoPlayerView(media: self, actionHandler: actionHandler)
            }
        case .openInBrowser(let url):
            Button {
                actionHandler?.presentScene(.safari(url: url), fromPost: nil, transition: .show)
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
    let actionHandler: MastodonPostMenuActionHandler?
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
                                            showImageGallery(focusing: img.id, withPlaceholderImages: viewModel.imageAttachments.map { viewModel.blurhashes[$0.id] })
                                        }
                                    }
                                }
                            }
                        }
                    
                    if let altText = img.basicData.altText, altText.isNotEmpty {
                        Button {
                            if let translation = viewModel.altTextTranslations?[img.id] {
                                actionHandler?.showOverlay(.altText(translation))
                            } else {
                                actionHandler?.showOverlay(.altText(altText))
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
    
    func showImageGallery(focusing: Mastodon.Entity.Attachment.ID, withPlaceholderImages placeholderImages: [UIImage?]) {
        guard let presentingViewController = viewModel.actionHandler?.mediaPreviewableViewController else { return }
        
        let focusedIndex = viewModel.imageAttachments.firstIndex { $0.id == focusing }
        
        let altTextTranslations = viewModel.altTextTranslations
        let altTexts = viewModel.imageAttachments.map { altTextTranslations?[$0.id] ?? $0.basicData.altText }
       
        let previewItem: MediaPreviewViewModel.PreviewItem = .attachments(viewModel.imageAttachments.map{ $0._legacyEntity }, initialIndex: focusedIndex, placeholderImages: placeholderImages, altTexts: altTexts)
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
        actionHandler?.presentScene(.mediaPreview(viewModel: mediaPreviewViewModel),
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
    let actionHandler: MastodonPostMenuActionHandler?
    
    init(imageAttachments: [MastodonImageAttachment], altTextTranslations: [String: String]?, actionHandler: MastodonPostMenuActionHandler?) {
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

struct AudioPlayerView: View {
    let media: MediaAttachment
    let url: URL
    @StateObject private var playerObserver = PlayerObserver()
    @State private var isDimmingButton = false
    
    init?(media: MediaAttachment) {
        switch media {
        case .audio:
            break
        default:
            return nil
        }
        self.media = media
        guard let url = media.attachmentInfo?.url else { return nil }
        self.url = url
    }
    
    var body: some View {
        VStack {
            // BUTTONS
            HStack {
                Button {
                    // jump 5 sec backwards
                    let currentTimeInSeconds = playerObserver.currentTimeInSeconds
                    let destination = max(0, currentTimeInSeconds - 5)
                    playerObserver.jump(to: destination)
                } label: {
                    Image(systemName: "5.arrow.trianglehead.counterclockwise")
                }
                
                Spacer()
                
                switch playerObserver.playingState {
                case .paused:
                    Button {
                        playerObserver.didPressPlay()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                case .waitingToPlayAtSpecifiedRate:
                    Button {
                        playerObserver.didPressPause()
                        isDimmingButton = false
                    } label: {
                        Image(systemName: "pause.fill")
                            .opacity(isDimmingButton ? 1.0 : 0.3)
                            .onAppear {
                                withAnimation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                ) {
                                    isDimmingButton = true
                                }
                            }
                    }
                case .playing:
                    Button {
                        playerObserver.didPressPause()
                    } label: {
                        Image(systemName: "pause.fill")
                    }
                @unknown default:
                    EmptyView()
                }
                
                Spacer()
                
                Button {
                    // jump 5 sec forward
                    guard let maxTime = playerObserver.totalSeconds else { return }
                    let currentTimeInSeconds = playerObserver.currentTimeInSeconds
                    let destination = min(maxTime, currentTimeInSeconds + 5)
                    playerObserver.jump(to: destination)
                } label: {
                    Image(systemName: "5.arrow.trianglehead.clockwise")
                }
            }
            .foregroundStyle(.primary)
            .font(.title)
            .frame(width: 200)
            .padding()
            
            // SLIDER
            Slider(
                value: Binding(
                    get: {
                        playerObserver.currentTimeInSeconds
                    },
                    set: { newValue in
                        playerObserver.jump(to: newValue)
                    }),
                in: 0...(playerObserver.totalSeconds ?? 1),
                label: {
                    Text("Audio timestamp")
                },
                minimumValueLabel: {
                    Text(timeLabel(fromSeconds: playerObserver.currentTimeInSeconds))
                        .font(.system(.caption, design: .monospaced))
                },
                maximumValueLabel: {
                    Text(timeLabel(fromSeconds: playerObserver.totalSeconds))
                        .font(.system(.caption, design: .monospaced))
                }
            )
            .accentColor(.secondary)
            .tint(.secondary)
            
            // ALT TEXT
            if let altText = media.attachmentInfo?.basicData.altText {
                Text(altText)
                    .foregroundStyle(.primary)
                    .font(.subheadline)
                    .italic()
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background {
            MastodonSecondaryBackground(fillInDarkModeOnly: true)
        }
        .environment(\.colorScheme, .dark)
        .onAppear() {
            playerObserver.setPlayer(withAsset: AVURLAsset(url: url))
            playerObserver.startObserving(shouldLoop: false)
        }
        .onDisappear() {
            playerObserver.didPressPause()
        }
    }
    
    func timeLabel(fromSeconds seconds: Double?) -> String {
        if let seconds {
            let sec = Int(seconds) % 60
            let min = Int(seconds) / 60
            return String(format: "%02d:%02d", min, sec)
        } else {
            return "--"
        }
    }
}

struct VideoPlayerView: View {
    let media: MediaAttachment
    let url: URL
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    @StateObject var playerObserver = PlayerObserver()
    let actionHandler: MastodonPostMenuActionHandler?
    @State var waitingToShowFullSize = false
    
    init?(media: MediaAttachment, actionHandler: MastodonPostMenuActionHandler?) {
        switch media {
        case .video, .gifv:
            break
        default:
            return nil
        }
        guard let attachmentInfo = media.attachmentInfo, let url = attachmentInfo.url else { return nil }
        self.media = media
        self.url = url
        self.actionHandler = actionHandler
    }
    
    var body: some View {
        ZStack {
            if let blurImage = playerObserver.blurImage {
                Image(uiImage: blurImage)
                    .resizable()
                    .scaledToFill()
            }
            
            if let player = playerObserver.getPlayer() {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                
                if shouldShowPlayButton {
                    switch playerObserver.playingState {
                    case .paused:
                        Button {
                            playerObserver.didPressPlay()
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
                    case .waitingToPlayAtSpecifiedRate:
                        ProgressView().progressViewStyle(.circular)
                    case .playing:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .onAppear() {
            self.playerObserver.setPlayer(withAsset: AVURLAsset(url: url))
            playerObserver.startObserving(shouldLoop: shouldLoop)
            if let attachmentInfo = media.attachmentInfo, let url = attachmentInfo.url, let blurhash = attachmentInfo.blurhash, let size = attachmentInfo.size {
                Task {
                    playerObserver.blurImage = try? await BlurhashImageCacheService.shared.image(blurhash: blurhash, size: size, url: url.absoluteString).singleOutput()
                }
            }
        }
        .onDisappear() {
            playerObserver.didPressPause()
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
        playerObserver.didPressPause()
        guard let _legacyEntity = media.attachmentInfo?._legacyEntity, let previewableViewController = actionHandler?.mediaPreviewableViewController else { return }
        let previewItem: MediaPreviewViewModel.PreviewItem = .attachments([_legacyEntity], initialIndex: 0, placeholderImages: [playerObserver.blurImage], altTexts: [media.attachmentInfo?.basicData.altText ?? ""])
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
        actionHandler?.presentScene(.mediaPreview(viewModel: mediaPreviewViewModel),
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

@MainActor
class PlayerObserver: ObservableObject {
    @Published var playingState: AVPlayer.TimeControlStatus = .paused
    @Published var totalSeconds: Double?
    @Published var currentTimeInSeconds: Double = 0.0
    @Published var blurImage: UIImage? = nil
    var mostRecentFrameInScreenCoordinates = CGRect(x: 50, y: 50, width: 50, height: 50)
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var playerStatusSubscription: AnyCancellable?
    private var playShouldSeekToStart = false
    
    func setPlayer(withAsset asset: AVAsset) {
        guard self.player == nil else { return }
        let _player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        self.player = _player
        
        func secondsFromDuration(_ duration: CMTime?) -> Double? {
            if let seconds = duration?.seconds, seconds > 0, seconds.isFinite, !seconds.isNaN {
                return seconds
            } else {
                return nil
            }
        }
        
        totalSeconds = secondsFromDuration(_player.currentItem?.duration)
        
        Task {
            let duration = try await asset.load(.duration)
            totalSeconds = secondsFromDuration(duration)
        }
    }
    
    func startObserving(shouldLoop: Bool) {
        guard let player else { assertionFailure(); return }
        player.pause()
        self.playerStatusSubscription?.cancel()
        self.playerStatusSubscription = player.publisher(for: \.timeControlStatus, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .assign(to: \.playingState, on: self)
        
        if timeObserverToken == nil {
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                DispatchQueue.main.async {
                    self?.totalSeconds = player.currentItem?.duration.seconds
                    self?.currentTimeInSeconds = time.seconds
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                if shouldLoop {
                    self?.player?.seek(to: .zero)
                    self?.player?.play()
                } else {
                    self?.playShouldSeekToStart = true
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.playerStatusSubscription?.cancel()
        player?.pause()
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
    }
    
    func didPressPlay() {
        if playShouldSeekToStart {
            player?.seek(to: .zero)
            playShouldSeekToStart = false
        }
        player?.play()
    }
    
    func didPressPause() {
        player?.pause()
    }
    
    func jump(to newTime: Double) {
        if let item = player?.currentItem {
            let scale = item.duration.timescale
            let time = CMTime(seconds: newTime, preferredTimescale: scale)
            player?.seek(to: time) { [weak self] finished in
                DispatchQueue.main.async {
                    guard let self, let totalSeconds = self.totalSeconds else { return }
                    self.currentTimeInSeconds = item.currentTime().seconds
                    self.playShouldSeekToStart = time.seconds >= totalSeconds
                }
            }
        }
    }
    
    func getPlayer() -> AVPlayer? {
        return player
    }
}
