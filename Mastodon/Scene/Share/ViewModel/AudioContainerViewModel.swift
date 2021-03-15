//
//  AudioContainerViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/9.
//

import CoreDataStack
import Foundation
import UIKit

class AudioContainerViewModel {
    static func configure(
        cell: StatusTableViewCell,
        audioAttachment: Attachment,
        audioService: AudioPlaybackService
    ) {
        guard let duration = audioAttachment.meta?.original?.duration else { return }
        let audioView = cell.statusView.audioView
        audioView.timeLabel.text = duration.asString(style: .positional)

        audioView.playButton.publisher(for: .touchUpInside)
            .sink { [weak audioService] _ in
                guard let audioService = audioService else { return }
                if audioAttachment === audioService.attachment {
                    if audioService.isPlaying() {
                        audioService.pause()
                    } else {
                        audioService.resume()
                    }
                    if audioService.currentTimeSubject.value == 0 {
                        audioService.playAudio(audioAttachment: audioAttachment)
                    }
                } else {
                    audioService.playAudio(audioAttachment: audioAttachment)
                }
            }
            .store(in: &cell.disposeBag)
        audioView.slider.publisher(for: .valueChanged)
            .sink { [weak audioService] slider in
                guard let audioService = audioService else { return }
                let slider = slider as! UISlider
                let time = Double(slider.value) * duration
                audioService.seekToTime(time: time)
            }
            .store(in: &cell.disposeBag)
        observePlayer(cell: cell, audioAttachment: audioAttachment, audioService: audioService)
        if audioAttachment != audioService.attachment {
            configureAudioView(audioView: audioView, audioAttachment: audioAttachment, playbackState: .stopped)
        }
    }

    static func observePlayer(
        cell: StatusTableViewCell,
        audioAttachment: Attachment,
        audioService: AudioPlaybackService
    ) {
        let audioView = cell.statusView.audioView
        var lastCurrentTimeSubject: TimeInterval?
        audioService.currentTimeSubject
            .throttle(for: 0.33, scheduler: DispatchQueue.main, latest: true)
            .compactMap { [weak audioService] time -> (TimeInterval, Float)? in
                defer {
                    lastCurrentTimeSubject = time
                }
                guard audioAttachment === audioService?.attachment else { return nil }
                guard let duration = audioAttachment.meta?.original?.duration else { return nil }

                if let lastCurrentTimeSubject = lastCurrentTimeSubject, time != 0.0 {
                    guard abs(time - lastCurrentTimeSubject) < 0.5 else { return nil } // debounce
                }

                guard !audioView.slider.isTracking else { return nil }
                return (time, Float(time / duration))
            }
            .sink(receiveValue: { time, progress in
                audioView.timeLabel.text = time.asString(style: .positional)
                audioView.slider.setValue(progress, animated: true)
            })
            .store(in: &cell.disposeBag)
        audioService.playbackState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { playbackState in
                if audioAttachment === audioService.attachment {
                    configureAudioView(audioView: audioView, audioAttachment: audioAttachment, playbackState: playbackState)
                } else {
                    configureAudioView(audioView: audioView, audioAttachment: audioAttachment, playbackState: .stopped)
                }
            })
            .store(in: &cell.disposeBag)
    }

    static func configureAudioView(
        audioView: AudioContainerView,
        audioAttachment: Attachment,
        playbackState: PlaybackState
    ) {
        switch playbackState {
        case .stopped:
            audioView.playButton.isSelected = false
            audioView.slider.isEnabled = false
            audioView.slider.setValue(0, animated: false)
        case .paused:
            audioView.playButton.isSelected = false
            audioView.slider.isEnabled = true
        case .playing, .readyToPlay:
            audioView.playButton.isSelected = true
            audioView.slider.isEnabled = true
        default:
            assertionFailure()
        }
        guard let duration = audioAttachment.meta?.original?.duration else { return }
        audioView.timeLabel.text = duration.asString(style: .positional)
    }
}
