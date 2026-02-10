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

struct MediaAttachmentView: View {
    let mediaAttachment: MediaAttachment
    let showOverlay: (MastodonTimelineOverlayView) -> ()
    let presentScene: (SceneCoordinator.Scene, Mastodon.Entity.Status.ID?, SceneCoordinator.Transition) -> ()
    @StateObject var playerObserver = PlayerObserver()
    
    var body: some View {
        switch mediaAttachment {
        case .emptyAttachment:
            Image(systemName: "questionmark.square.dashed")
        case .images(let attachments, let altTextTranslations):
            ConcealableMediaAttachmentView() {
                ImageGridView(showOverlay: showOverlay)
                    .environment(ImageGalleryViewModel(imageAttachments: attachments, altTextTranslations: altTextTranslations))
            }
        case .audio:
            AudioPlayerView(media: mediaAttachment)
        case .gifv, .video:
            ConcealableMediaAttachmentView() {
                ZStack {
                    VideoPlayerView(playerObserver: playerObserver, media: self.mediaAttachment, originalSize: self.mediaAttachment.attachmentInfo?.imageDetails?.originalSize ?? .zero, showOverlay: showOverlay)
                    playerObserver.playButton(playerObserver.playingState)
                }
            }
        case .openInBrowser(let url):
            Button {
                presentScene(.safari(url: url), nil, .show)
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
    let contentView: Content

    init(@ViewBuilder content: () -> Content) {
        self.contentView = content()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) { // places the Hide/Show button, if there is one
            
            contentView
            
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
    let showOverlay: (MastodonTimelineOverlayView)->()
    
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
                            showOverlay(.images(focusedImage: img.id, viewModel))
                        }
                    
                    if let altText = img.basicData.altText, altText.isNotEmpty {
                        Button {
                            if let translation = viewModel.altTextTranslations?[img.id] {
                                showOverlay(.altText(translation))
                            } else {
                                showOverlay(.altText(altText))
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
    let idToIndex: [ Mastodon.Entity.Attachment.ID : Int ]
    
    init(imageAttachments: [MastodonImageAttachment], altTextTranslations: [String: String]?) {
        self.imageAttachments = imageAttachments
        self.altTextTranslations = altTextTranslations
        idToIndex = imageAttachments.enumerated().reduce(into: [ Mastodon.Entity.Attachment.ID : Int ](), { partialResult, element in
            partialResult[element.1.id] = element.0
        })
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
            playerObserver.setPlayer(withAsset: AVURLAsset(url: url), respectDeviceSilentSetting: false)
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
    let originalSize: CGSize
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    @ObservedObject var playerObserver: PlayerObserver
    let showOverlay: (MastodonTimelineOverlayView)->()
    
    init?(playerObserver: PlayerObserver, media: MediaAttachment, originalSize: CGSize, showOverlay: @escaping (MastodonTimelineOverlayView)->()) {
        switch media {
        case .video, .gifv:
            break
        default:
            return nil
        }
        guard let attachmentInfo = media.attachmentInfo, let url = attachmentInfo.url else { return nil }
        self.playerObserver = playerObserver
        self.originalSize = originalSize
        self.media = media
        self.url = url
        self.showOverlay = showOverlay
    }
    
    var respectDeviceSilentSetting: Bool {
        switch media {
        case .gifv:
            true
        case .video, .audio:
            false
        case .emptyAttachment, .images, .notYetImplemented, .openInBrowser:
            true
        }
    }
    
    var body: some View {
        ZStack {
            if let player = playerObserver.getPlayer() {
                VideoPlayer(player: player)
                    .opacity(playerObserver.isReadyToPlay ? 1 : 0)
                    .aspectRatio(originalSize.aspectRatio, contentMode: .fit)
                    .background() {
                        if let blurImage = playerObserver.blurImage {
                            Image(uiImage: blurImage)
                                .resizable()
                                .scaledToFill()
                        }
                    }
            } else if let blurImage = playerObserver.blurImage {
                Image(uiImage: blurImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipped() // prevents the blurhash image from overhanging the video if it somehow has a slightly different aspect ratio
        .overlay {
            Button {
                playerObserver.didPressPause()
                showOverlay(.video(media))
            } label: {
                Rectangle().fill(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.borderless)
        }
        .onAppear() {
            self.playerObserver.setPlayer(withAsset: AVURLAsset(url: url), respectDeviceSilentSetting: respectDeviceSilentSetting)
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
    
    func aspectFittingHeightToFillWidth(containerWidth: CGFloat) -> CGFloat {
        guard originalSize != .zero else { return 200 }
        let aspect = originalSize.aspectRatio
        let fittingHeight = containerWidth / aspect
        print("fitting size is \(containerWidth) x \(fittingHeight)")
        return fittingHeight
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
    @Published var isReadyToPlay = false
    @Published var totalSeconds: Double?
    @Published var currentTimeInSeconds: Double = 0.0
    @Published var blurImage: UIImage? = nil
    var mostRecentFrameInScreenCoordinates = CGRect(x: 50, y: 50, width: 50, height: 50)
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var playerStatusSubscription: AnyCancellable?
    private var playerReadinessSubscription: AnyCancellable?
    private var playShouldSeekToStart = false
    private var respectDeviceSilentSetting = false
    
    func setPlayer(withAsset asset: AVAsset, respectDeviceSilentSetting: Bool) {
        self.respectDeviceSilentSetting = respectDeviceSilentSetting
        
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
            .sink { [weak self] newValue in
                self?.playingState = newValue
            }
        self.playerReadinessSubscription?.cancel()
        self.playerReadinessSubscription = player.publisher(for: \.currentItem?.isPlaybackLikelyToKeepUp, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                let newDerivedValue = newValue == true
                if newDerivedValue != self.isReadyToPlay {
                    withAnimation {
                        self.isReadyToPlay = newDerivedValue
                    }
                }
            }
        
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
                guard let self else { MediaPreviewVideoViewModel.endAudioSession(); return }
                if shouldLoop {
                    self.player?.seek(to: .zero)
                    self.player?.play()
                } else {
                    if !self.respectDeviceSilentSetting {
                        MediaPreviewVideoViewModel.endAudioSession()
                    }
                    self.playShouldSeekToStart = true
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.playerStatusSubscription?.cancel()
        if !respectDeviceSilentSetting {
            MediaPreviewVideoViewModel.endAudioSession()
        }
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
        if !respectDeviceSilentSetting {
            MediaPreviewVideoViewModel.startAudioSession()
        }
        player?.play()
    }
    
    func didPressPause() {
        if !respectDeviceSilentSetting {
            MediaPreviewVideoViewModel.endAudioSession()
        }
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
    
    @ViewBuilder func playButton(_ _playingState: AVPlayer.TimeControlStatus) -> some View {
        switch _playingState {
        case .paused:
            Button {
                self.didPressPlay()
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
