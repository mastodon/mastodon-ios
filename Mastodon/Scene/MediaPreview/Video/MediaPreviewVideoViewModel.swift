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
    let context: AppContext
    let item: Item
    
    // output
    public private(set) var player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    @Published var playbackState = PlaybackState.unknown
    
    init(context: AppContext, item: Item) {
        self.context = context
        self.item = item
        // end init

        switch item {
        case .video(let mediaContext):
            guard let assertURL = mediaContext.assetURL else { return }
            let playerItem = AVPlayerItem(url: assertURL)
            let _player = AVPlayer(playerItem: playerItem)
            self.player = _player

        case .gif(let mediaContext):
            guard let assertURL = mediaContext.assetURL else { return }
            let playerItem = AVPlayerItem(url: assertURL)
            let _player = AVQueuePlayer(playerItem: playerItem)
            _player.isMuted = true
            self.player = _player
            if let templateItem = _player.items().first {
                let _playerLooper = AVPlayerLooper(player: _player, templateItem: templateItem)
                self.playerLooper = _playerLooper
            }
        }
        
        guard let player = player else {
            assertionFailure()
            return
        }

        // setup player state observer
        $playbackState
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .unknown, .buffering, .readyToPlay:
                    break
                case .playing:
                    if case .video = item {
                        try? AVAudioSession.sharedInstance().setCategory(.playback)
                    }
                    try? AVAudioSession.sharedInstance().setActive(true)
                case .paused, .stopped, .failed:
                    try? AVAudioSession.sharedInstance().setCategory(.ambient)  // set to ambient to allow mixed (needed for GIFV)
                    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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
