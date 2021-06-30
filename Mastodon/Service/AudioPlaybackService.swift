//
//  AudioPlayer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/8.
//

import AVFoundation
import Combine
import CoreDataStack
import Foundation
import UIKit
import os.log

final class AudioPlaybackService: NSObject {
    
    static let appWillPlayAudioNotification = NSNotification.Name(rawValue: "org.joinmastodon.app.audio-playback-service.appWillPlayAudio")
    
    var disposeBag = Set<AnyCancellable>()

    var player = AVPlayer()
    var timeObserver: Any?
    var statusObserver: Any?
    var attachment: Attachment?

    let playbackState = CurrentValueSubject<PlaybackState, Never>(PlaybackState.unknown)

    let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)

    override init() {
        super.init()
        addObserver()

        playbackState
            .receive(on: RunLoop.main)
            .sink { status in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: audio status: %s", ((#file as NSString).lastPathComponent), #line, #function, status.description)
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
}

extension AudioPlaybackService {
    func playAudio(audioAttachment: Attachment) {
        guard let url = URL(string: audioAttachment.url) else {
            return
        }

        notifyWillPlayAudioNotification()
        if audioAttachment == attachment {
            if self.playbackState.value == .stopped {
                self.seekToTime(time: .zero)
            }
            player.play()
            self.playbackState.value = .playing
            return
        }
        player.pause()
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        attachment = audioAttachment
        player.play()
        playbackState.value = .playing
    }

    func addObserver() {
        NotificationCenter.default.publisher(for: VideoPlayerViewModel.appWillPlayVideoNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.pauseIfNeed()
            }
            .store(in: &disposeBag)
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main, using: { [weak self] time in
            guard let self = self else { return }
            self.currentTimeSubject.value = time.seconds
        })
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
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.player.seek(to: .zero)
                self.playbackState.value = .stopped
                self.currentTimeSubject.value = 0
            }
            .store(in: &disposeBag)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification, object: nil)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.pause()
            }
            .store(in: &disposeBag)
    }

    func notifyWillPlayAudioNotification() {
        NotificationCenter.default.post(name: AudioPlaybackService.appWillPlayAudioNotification, object: nil)
    }
    func isPlaying() -> Bool {
        return playbackState.value == .readyToPlay || playbackState.value == .playing
    }
    func resume() {
        notifyWillPlayAudioNotification()
        player.play()
        playbackState.value = .playing
    }

    func pause() {
        player.pause()
        playbackState.value = .paused
    }
    func pauseIfNeed() {
        if isPlaying() {
            pause()
        }
    }
    func seekToTime(time: TimeInterval) {
        player.seek(to: CMTimeMake(value:Int64(time), timescale: 1))
    }
}

extension AudioPlaybackService {
    func viewDidDisappear(from viewController: UIViewController?) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        pause()
    }
}
