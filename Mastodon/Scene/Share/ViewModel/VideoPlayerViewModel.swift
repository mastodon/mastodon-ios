//
//  VideoPlayerViewModel.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/10.
//

import AVKit
import Combine
import CoreDataStack
import os.log
import UIKit

final class VideoPlayerViewModel {
    var disposeBag = Set<AnyCancellable>()

    static let appWillPlayVideoNotification = NSNotification.Name(rawValue: "org.joinmastodon.app.video-playback-service.appWillPlayVideo")
    // input
    let previewImageURL: URL?
    let videoURL: URL
    let videoSize: CGSize
    let videoKind: Kind
            
    var isTransitioning = false
    var isFullScreenPresentationing = false
    var isPlayingWhenEndDisplaying = false
    
    // prevent player state flick when tableView reload
    private typealias Play = Bool
    private let debouncePlayingState = PassthroughSubject<Play, Never>()
    
    private var updateDate = Date()
    
    // output
    let player: AVPlayer
    private(set) var looper: AVPlayerLooper? // works with AVQueuePlayer (iOS 10+)
    
    private var timeControlStatusObservation: NSKeyValueObservation?
    let timeControlStatus = CurrentValueSubject<AVPlayer.TimeControlStatus, Never>(.paused)
    let playbackState = CurrentValueSubject<PlaybackState, Never>(PlaybackState.unknown)

    init(previewImageURL: URL?, videoURL: URL, videoSize: CGSize, videoKind: VideoPlayerViewModel.Kind) {
        self.previewImageURL = previewImageURL
        self.videoURL = videoURL
        self.videoSize = videoSize
        self.videoKind = videoKind
        
        let playerItem = AVPlayerItem(url: videoURL)
        let player = videoKind == .gif ? AVQueuePlayer(playerItem: playerItem) : AVPlayer(playerItem: playerItem)
        player.isMuted = true
        self.player = player
        
        if videoKind == .gif {
            setupLooper()
        }
        
        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: player state: %s", (#file as NSString).lastPathComponent, #line, #function, player.timeControlStatus.debugDescription)
            self.timeControlStatus.value = player.timeControlStatus
        }

        player.publisher(for: \.status, options: [.initial, .new])
            .sink(receiveValue: { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .failed:
                    self.playbackState.value = .failed
                case .readyToPlay:
                    self.playbackState.value = .readyToPlay
                case .unknown:
                    self.playbackState.value = .unknown
                @unknown default:
                    assertionFailure()
                }
            })
            .store(in: &disposeBag)

        timeControlStatus
            .sink { [weak self] timeControlStatus in
                guard let self = self else { return }

                // emit playing event
                if timeControlStatus == .playing {
                    NotificationCenter.default.post(name: VideoPlayerViewModel.appWillPlayVideoNotification, object: nil)
                }

                switch timeControlStatus {
                case .paused:
                    self.playbackState.value = .paused
                case .waitingToPlayAtSpecifiedRate:
                    self.playbackState.value = .buffering
                case .playing:
                    self.playbackState.value = .playing
                @unknown default:
                    assertionFailure()
                    self.playbackState.value = .unknown
                }
            }
            .store(in: &disposeBag)
        
        debouncePlayingState
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] isPlay in
                guard let self = self else { return }
                isPlay ? self.play() : self.pause()
            }
            .store(in: &disposeBag)

        let sessionName = videoKind == .gif ? "GIF" : "Video"
        playbackState
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s status: %s", ((#file as NSString).lastPathComponent), #line, #function, sessionName, status.description)
                guard let self = self else { return }
                // only update audio session for video
                guard self.videoKind == .video else { return }
                switch status {
                case .unknown, .buffering, .readyToPlay:
                    break
                case .playing:
                    try? AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                    try? AVAudioSession.sharedInstance().setActive(true)
                case .paused, .stopped, .failed:
                    try? AVAudioSession.sharedInstance().setCategory(.ambient)
                    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                }
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        timeControlStatusObservation = nil
    }
}

extension VideoPlayerViewModel {
    enum Kind {
        case gif
        case video
    }
}

extension VideoPlayerViewModel {
    func setupLooper() {
        guard looper == nil, let queuePlayer = player as? AVQueuePlayer else { return }
        guard let templateItem = queuePlayer.items().first else { return }
        looper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)
    }
    
    func play() {
        switch videoKind {
        case .gif:
            break
        case .video:
            break
//            try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default)
        }

        player.play()
        updateDate = Date()
    }
    
    func pause() {
        player.pause()
        updateDate = Date()
    }
    
    func willDisplay() {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: url: %s", (#file as NSString).lastPathComponent, #line, #function, videoURL.debugDescription)
        
        switch videoKind {
        case .gif:
            play() // always auto play GIF
        case .video:
            guard isPlayingWhenEndDisplaying else { return }
            // mute before resume
            if updateDate.timeIntervalSinceNow < -3 {
                player.isMuted = true
            }
            debouncePlayingState.send(true)
        }
        
        updateDate = Date()
    }
    
    func didEndDisplaying() {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: url: %s", (#file as NSString).lastPathComponent, #line, #function, videoURL.debugDescription)
        
        isPlayingWhenEndDisplaying = timeControlStatus.value != .paused
        switch videoKind {
        case .gif:
            pause() // always pause GIF immediately
        case .video:
            debouncePlayingState.send(false)
        }
        
        updateDate = Date()
    }
}
