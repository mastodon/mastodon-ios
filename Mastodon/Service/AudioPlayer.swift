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

final class AudioPlayer: NSObject {
    
    static let appWillPlayAudioNotification = NSNotification.Name(rawValue: "appWillPlayAudioNotification")
    
    var disposeBag = Set<AnyCancellable>()

    var player = AVPlayer()
    var timeObserver: Any?
    var statusObserver: Any?
    var attachment: Attachment?

    let session = AVAudioSession.sharedInstance()
    let playbackState = CurrentValueSubject<PlaybackState, Never>(PlaybackState.unknown)
    
    // MARK: - singleton
    public static let shared = AudioPlayer()

    let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)

    private override init() {
        super.init()
        addObserver()
    }
}

extension AudioPlayer {
    func playAudio(audioAttachment: Attachment) {
        guard let url = URL(string: audioAttachment.url) else {
            return
        }
        do {
            try session.setCategory(.playback)
        } catch {
            print(error)
            return
        }

        pushWillPlayAudioNotification()
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
        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.publisher(for: UIDevice.proximityStateDidChangeNotification, object: nil)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if UIDevice.current.proximityState == true {
                    do {
                        try self.session.setCategory(.playAndRecord)
                    } catch {
                        print(error)
                        return
                    }
                } else {
                    do {
                        try self.session.setCategory(.playback)
                    } catch {
                        print(error)
                        return
                    }
                }
            }
            .store(in: &disposeBag)
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
        player.publisher(for: \.status, options: .new)
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

    func pushWillPlayAudioNotification() {
        NotificationCenter.default.post(name: AudioPlayer.appWillPlayAudioNotification, object: nil)
    }
    func isPlaying() -> Bool {
        return playbackState.value == .readyToPlay || playbackState.value == .playing
    }
    func resume() {
        pushWillPlayAudioNotification()
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
