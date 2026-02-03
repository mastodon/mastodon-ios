//
//  MediaPreviewVideoViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-9.
//

import UIKit
import AVKit
import Combine
import AlamofireImage
import MastodonCore

final class MediaPreviewVideoViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let item: Item
    
    // output
    public let player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    @Published var playbackState = PlaybackState.unknown
    
    init(item: Item) {
        self.item = item
        // end init

        switch item {
        case .video(let mediaContext):
            guard let assetURL = mediaContext.assetURL else { player = nil; return }
            let playerItem = AVPlayerItem(url: assetURL)
            let _player = AVPlayer(playerItem: playerItem)
            self.player = _player

        case .gif(let mediaContext):
            guard let assetURL = mediaContext.assetURL else { player = nil; return }
            let playerItem = AVPlayerItem(url: assetURL)
            let _player = AVQueuePlayer(playerItem: playerItem)
            _player.isMuted = true
            self.player = _player
            if let templateItem = _player.items().first {
                let _playerLooper = AVPlayerLooper(player: _player, templateItem: templateItem)
                self.playerLooper = _playerLooper
            }
        }
        
        guard let player else {
            assertionFailure("no url for playable media")
            return
        }

        // setup player state observer
        $playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self, let player = self.player else { return }
                switch status {
                case .unknown, .buffering, .readyToPlay:
                    break
                case .playing:
                    MediaPreviewVideoViewModel.startAudioSession()
                    player.play()
                case .paused, .stopped, .failed:
                    MediaPreviewVideoViewModel.endAudioSession()
                }
            }
            .store(in: &disposeBag)
        
        player.publisher(for: \.status, options: [.initial, .new])
            .sink(receiveValue: { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .failed:
                    self.playbackState = .failed
                case .readyToPlay:
                    self.playbackState = .readyToPlay
                case .unknown:
                    self.playbackState = .unknown
                @unknown default:
                    assertionFailure()
                }
            })
            .store(in: &disposeBag)
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let playerItem = notification.object as? AVPlayerItem,
                      let urlAsset = playerItem.asset as? AVURLAsset
                else { return }
                print(urlAsset.url)
                guard urlAsset.url == item.assetURL else { return }
                self.playbackState = .stopped
            }
            .store(in: &disposeBag)
    }
    
    // MARK: Manage AVAudioSession
    static var activeAudioSessionRequestCounter = 0
    static func startAudioSession() {
        Task { @MainActor in
            activeAudioSessionRequestCounter += 1
            guard activeAudioSessionRequestCounter == 1 else { return }
            try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            // https://developer.apple.com/documentation/avfaudio/avaudiosession/setactive(_:options:)
            //  "If you attempt to activate a session with category record or playAndRecord when another app is already hosting a call, then your session fails with the error AVAudioSessionErrorInsufficientPriority."
            //  "The session fails to activate if another audio session has higher priority than yours (such as a phone call) and neither audio session allows mixing."
            // "mixWithOthers: If you set the audio session category to ambient, the session automatically sets this option. If you set this option, your app mixes its audio with audio playing in background apps, such as the Music app."
            // CONCLUSION: Since we are never attempting to record and we allow mixing with others, activating the session should never fail, so there is no need to handle an error here.
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    static func endAudioSession() {
        Task { @MainActor in
            guard activeAudioSessionRequestCounter != 0 else { return }
            activeAudioSessionRequestCounter -= 1
            guard activeAudioSessionRequestCounter == 0 else { return }
            try? AVAudioSession.sharedInstance().setCategory(.ambient)  // set to ambient to allow mixed (needed for GIFV)
            // https://developer.apple.com/documentation/avfaudio/avaudiosession/setactive(_:options:)
            // "Deactivating an audio session with running audio objects stops the objects, makes the session inactive, and returns an AVAudioSessionErrorCodeIsBusy error."
            // "When your app deactivates a session, the return value is false but the active state changes to deactivate."
            // CONCLUSION: Deactivating a session always succeeds, even when an error is thrown, so any error thrown here can be ignored.
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    deinit {
        if playbackState == .playing {
            MediaPreviewVideoViewModel.endAudioSession()
        }
    }
}

extension MediaPreviewVideoViewModel {
    
    enum Item {
        case video(RemoteVideoContext)
        case gif(RemoteGIFContext)
        
        var previewURL: URL? {
            switch self {
            case .video(let mediaContext):      return mediaContext.previewURL
            case .gif(let mediaContext):        return mediaContext.previewURL
            }
        }
        
        var assetURL: URL? {
            switch self {
            case .video(let mediaContext):      return mediaContext.assetURL
            case .gif(let mediaContext):        return mediaContext.assetURL
            }
        }
    }
    
    struct RemoteVideoContext {
        let assetURL: URL?
        let previewURL: URL?
        let altText: String?
        // let thumbnail: UIImage?
    }
    
    struct RemoteGIFContext {
        let assetURL: URL?
        let previewURL: URL?
        let altText: String?
    }
    
}
